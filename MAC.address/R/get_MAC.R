#' Get the MAC addresses of this device
#'
#' Lists the hardware (MAC) address of each network interface of the local
#' machine. Works on Linux (reads `/sys/class/net`), macOS and other Unix
#' systems (parses `ifconfig -a`) and Windows (parses `getmac`).
#'
#' @param include_null Logical. Keep interfaces whose address is
#'   `00:00:00:00:00:00` (e.g. the loopback interface)?
#'
#' @return A named character vector of normalized MAC addresses
#'   (`XX:XX:XX:XX:XX:XX`), named by interface. If the addresses cannot be
#'   read, a warning is given and an empty vector is returned.
#' @export
#'
#' @examples
#' get_MAC()
get_MAC <- function(include_null = FALSE) {
  macs <- switch(
    get_os(),
    Windows = mac_windows(),
    Linux   = if (dir.exists("/sys/class/net")) mac_linux() else mac_ifconfig(),
    mac_ifconfig()
  )

  macs <- macs[is_MAC(macs)]
  macs[] <- normalize_MAC(macs)
  if (!include_null) macs <- macs[macs != "00:00:00:00:00:00"]
  macs
}

#' Operating system name, as reported by `Sys.info()`
#' @noRd
get_os <- function() {
  Sys.info()[["sysname"]]
}

#' MAC addresses read from `/sys/class/net/<interface>/address`
#' @noRd
mac_linux <- function() {
  ifaces <- list.files("/sys/class/net")
  macs <- vapply(ifaces, function(i) {
    path <- file.path("/sys/class/net", i, "address")
    if (!file.exists(path)) return(NA_character_)
    tryCatch(trimws(readLines(path, n = 1, warn = FALSE)),
             error = function(e) NA_character_)
  }, character(1))
  macs[!is.na(macs)]
}

#' MAC addresses from `ifconfig -a` (macOS and other Unix systems)
#' @noRd
mac_ifconfig <- function() {
  parse_ifconfig(run_command("ifconfig", "-a"))
}

#' Parse `ifconfig` output
#'
#' Interface blocks start at column 1 (`en0: flags=...`); the address appears
#' in an indented `ether`/`lladdr`/`HWaddr` line of the same block.
#'
#' @param lines Character vector, one element per output line.
#' @return Named character vector of MAC addresses, named by interface.
#' @noRd
parse_ifconfig <- function(lines) {
  macs <- character()
  iface <- NA_character_
  for (line in lines) {
    if (grepl("^[^[:space:]]", line)) {
      iface <- sub("[:[:space:]].*$", "", line)
    }
    found <- search_MAC(line, sep = ":")
    if (!is.na(iface) && length(found) > 0 && !iface %in% names(macs)) {
      macs[iface] <- found[1]
    }
  }
  macs
}

#' MAC addresses from `getmac` (Windows)
#' @noRd
mac_windows <- function() {
  parse_getmac(run_command("getmac", c("/v", "/fo", "csv", "/nh")))
}

#' Run a system command, returning its output lines
#'
#' Gives a warning and returns an empty vector if the command is not available
#' or fails, so that [get_MAC()] never stops with an error.
#'
#' @param command,args Passed to [system2()].
#' @return Character vector with the standard output.
#' @noRd
run_command <- function(command, args = character()) {
  tryCatch(
    suppressWarnings(system2(command, args, stdout = TRUE, stderr = FALSE)),
    error = function(e) {
      warning("Could not run '", command, "': ", conditionMessage(e),
              call. = FALSE)
      character()
    }
  )
}

#' Parse `getmac /v /fo csv /nh` output
#'
#' Columns: Connection Name, Network Adapter, Physical Address, Transport Name.
#'
#' @param lines Character vector, one element per output line.
#' @return Named character vector of MAC addresses, named by connection.
#' @noRd
parse_getmac <- function(lines) {
  lines <- lines[nzchar(trimws(lines))]
  if (length(lines) == 0) return(character())
  tab <- utils::read.csv(text = lines, header = FALSE, stringsAsFactors = FALSE)
  stats::setNames(tab[[3]], tab[[1]])
}
