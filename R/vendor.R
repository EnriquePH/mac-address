#' Download the IEEE OUI registry
#'
#' Downloads the public IEEE registries of MAC address blocks and combines them
#' in one data frame. The result is cached on disk, so later calls do not need
#' an internet connection.
#'
#' Registries:
#' * `MA-L`: MAC Address Block Large (24-bit prefix, the classic OUI).
#' * `MA-M`: MAC Address Block Medium (28-bit prefix).
#' * `MA-S`: MAC Address Block Small (36-bit prefix).
#'
#' @param registry Which registries to download.
#' @param refresh Logical. Download again even if a cached copy exists?
#' @param cache_dir Directory where the CSV files are cached. By default, the
#'   user cache directory given by `tools::R_user_dir("MAC.address", "cache")`.
#'
#' To remove the cached files, delete the cache directory, e.g.
#' `unlink(tools::R_user_dir("MAC.address", "cache"), recursive = TRUE)`.
#'
#' @return A data frame with columns `registry`, `assignment` (hexadecimal
#'   prefix), `organization` and `address`. If a registry cannot be downloaded
#'   (e.g. no internet connection), an error with an informative message is
#'   given.
#' @export
#'
#' @examples
#' \donttest{
#' # Needs an internet connection; the MA-L registry is about 4 MB
#' oui <- try(get_oui_registry("MA-L", cache_dir = tempdir()))
#' if (is.data.frame(oui)) head(oui)
#' }
get_oui_registry <- function(registry = c("MA-L", "MA-M", "MA-S"),
                             refresh = FALSE,
                             cache_dir = NULL) {
  registry <- match.arg(registry, several.ok = TRUE)
  if (is.null(cache_dir)) cache_dir <- tools::R_user_dir("MAC.address", "cache")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  tables <- lapply(registry, function(r) {
    url <- oui_urls[[r]]
    file <- file.path(cache_dir, basename(url))
    if (refresh || !file.exists(file)) download_registry(url, file)
    tab <- utils::read.csv(file, colClasses = "character", encoding = "UTF-8")
    names(tab) <- c("registry", "assignment", "organization", "address")
    tab
  })

  out <- do.call(rbind, tables)
  out[] <- lapply(out, trimws)
  out$assignment <- toupper(out$assignment)
  out
}

#' Download a registry file
#'
#' Downloads to a temporary file first, so a failed download never leaves a
#' broken file in the cache.
#'
#' @param url,file Source URL and destination path.
#' @noRd
download_registry <- function(url, file) {
  old <- options(timeout = max(300, getOption("timeout")))
  on.exit(options(old), add = TRUE)

  message("Downloading ", url)
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  ok <- tryCatch(
    utils::download.file(url, tmp, quiet = TRUE, mode = "wb") == 0,
    error = function(e) FALSE,
    warning = function(w) FALSE
  )
  if (!ok || !file.copy(tmp, file, overwrite = TRUE)) {
    stop("Could not download the IEEE registry from ", url, ".\n",
         "Check your internet connection and try again.", call. = FALSE)
  }
  invisible(file)
}

#' Download URLs of the IEEE registries
#' @noRd
oui_urls <- list(
  "MA-L" = "https://standards-oui.ieee.org/oui/oui.csv",
  "MA-M" = "https://standards-oui.ieee.org/oui28/mam.csv",
  "MA-S" = "https://standards-oui.ieee.org/oui36/oui36.csv"
)

#' Find the manufacturer of a MAC address
#'
#' Looks up the organization that owns each MAC address block, using the
#' longest matching prefix (MA-S, then MA-M, then MA-L).
#'
#' Locally administered addresses (see [is_local_MAC()]), such as randomized
#' Wi-Fi addresses, are not part of the IEEE registries and usually return `NA`.
#'
#' @param mac A character vector of MAC addresses in any supported notation.
#' @param registry A data frame as returned by [get_oui_registry()], with at
#'   least the columns `assignment` and `organization`.
#'
#' @return A character vector with the organization names (`NA` if unknown).
#' @export
#'
#' @examples
#' # A small registry, to run without internet access
#' registry <- data.frame(
#'   registry = c("MA-L", "MA-M"),
#'   assignment = c("00000C", "70B3D51"),
#'   organization = c("Cisco Systems, Inc", "Example Medium Co")
#' )
#' macs <- c("00-00-0C-12-34-56", "70:B3:D5:1A:00:00", "02:00:00:00:00:01")
#' lookup_vendor(macs, registry)
#'
#' \donttest{
#' # With the full IEEE registries (needs an internet connection)
#' oui <- try(get_oui_registry(cache_dir = tempdir()))
#' if (is.data.frame(oui)) lookup_vendor(get_MAC(), oui)
#' }
lookup_vendor <- function(mac, registry = get_oui_registry()) {
  needed <- c("assignment", "organization")
  if (!is.data.frame(registry) || !all(needed %in% names(registry))) {
    stop("`registry` must be a data frame with columns 'assignment' and ",
         "'organization', as returned by get_oui_registry().", call. = FALSE)
  }
  hex <- normalize_MAC(mac, sep = "")
  assignment <- toupper(as.character(registry$assignment))
  organization <- as.character(registry$organization)
  vendor <- rep(NA_character_, length(hex))

  # Longest prefix first, so a more specific assignment wins
  for (n in c(9, 7, 6)) {
    block <- which(nchar(assignment) == n)
    todo <- is.na(vendor) & !is.na(hex)
    prefix <- substr(hex[todo], 1, n)
    vendor[todo] <- organization[block][match(prefix, assignment[block])]
  }
  vendor
}

#' Check whether MAC addresses are locally administered
#'
#' Locally administered addresses (e.g. randomized addresses used by phones
#' for Wi-Fi privacy, or virtual machines) have the second least significant
#' bit of the first octet set.
#'
#' @param mac A character vector of MAC addresses.
#'
#' @return A logical vector (`NA` for invalid addresses).
#' @export
#'
#' @examples
#' is_local_MAC(c("02:00:00:00:00:01", "1C:4C:7E:30:D8:13"))
is_local_MAC <- function(mac) {
  first_octet <- strtoi(substr(normalize_MAC(mac), 1, 2), base = 16)
  bitwAnd(first_octet, 2L) > 0
}
