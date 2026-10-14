#' Search MAC addresses in a text
#'
#' Extracts every MAC-48 address found in `txt`. Supports the usual notations:
#' colon (`1C:4C:7E:30:D8:13`), hyphen (`1C-4C-7E-30-D8-13`) and Cisco dotted
#' (`1C4C.7E30.D813`). The separator must be the same inside each address, and
#' longer hexadecimal sequences (e.g. EUI-64 or IPv6) are not partially matched.
#'
#' @param txt A character vector with the text to search.
#' @param sep A character vector with the allowed single-character separators.
#'   Use `character()` to search only the dotted notation.
#' @param dotted Logical. Also search Cisco dotted notation (`xxxx.xxxx.xxxx`)?
#' @param normalize Logical. If `TRUE`, results are returned in canonical
#'   `XX:XX:XX:XX:XX:XX` form (see [normalize_MAC()]); otherwise they are
#'   returned as found, in upper case.
#' @param unique Logical. Remove duplicated addresses?
#'
#' @return A character vector with the MAC addresses found (possibly empty).
#' @export
#'
#' @examples
#' sample_txt <- "MAC addresses 1C:4C:7E:30:d8:13 and 00-1A-2B-3C-4D-5E"
#' search_MAC(sample_txt)
#' search_MAC(sample_txt, normalize = TRUE)
#' search_MAC("Cisco style: 001a.2b3c.4d5e")
search_MAC <- function(txt, sep = c(":", "-"), dotted = TRUE,
                       normalize = FALSE, unique = FALSE) {
  stopifnot(
    is.character(txt), is.character(sep), all(nchar(sep) == 1),
    length(sep) > 0 || isTRUE(dotted)
  )

  pattern <- mac_pattern(sep, dotted)
  matches <- regmatches(txt, gregexpr(pattern, txt, perl = TRUE))
  macs <- toupper(unlist(matches, use.names = FALSE))

  if (normalize) macs <- normalize_MAC(macs)
  if (unique) macs <- unique(macs)
  macs
}

#' Normalize MAC addresses
#'
#' Converts MAC addresses written in any supported notation to a common
#' upper-case format.
#'
#' @param mac A character vector of MAC addresses.
#' @param sep Separator to use in the output. Use `""` for plain hexadecimal.
#'
#' @return A character vector. Invalid addresses become `NA`.
#' @export
#'
#' @examples
#' normalize_MAC(c("1c-4c-7e-30-d8-13", "1c4c.7e30.d813", "not a MAC"))
#' normalize_MAC("1C:4C:7E:30:D8:13", sep = "-")
normalize_MAC <- function(mac, sep = ":") {
  stopifnot(is.character(sep), length(sep) == 1, !is.na(sep))
  hex <- toupper(gsub("[^0-9A-Fa-f]", "", mac))
  out <- vapply(hex, function(h) {
    paste(substring(h, seq(1, 11, 2), seq(2, 12, 2)), collapse = sep)
  }, character(1), USE.NAMES = FALSE)
  out[!is_MAC(mac)] <- NA_character_
  out
}

#' Check whether strings are valid MAC addresses
#'
#' @param x A character vector.
#'
#' @return A logical vector, `TRUE` where the whole string is a MAC address in
#'   colon, hyphen or Cisco dotted notation.
#' @export
#'
#' @examples
#' is_MAC(c("1C:4C:7E:30:D8:13", "1C:4C:7E:30:D8", "1C:4C-7E:30:D8:13"))
is_MAC <- function(x) {
  !is.na(x) & grepl(paste0("^(?:", mac_pattern(), ")$"), x, perl = TRUE)
}

#' Regular expression (PCRE) for MAC-48 addresses
#'
#' A backreference forces the same separator throughout the address, and the
#' lookarounds avoid matching pieces of longer hexadecimal sequences.
#'
#' @inheritParams search_MAC
#' @return A string, to be used with `perl = TRUE`.
#' @noRd
mac_pattern <- function(sep = c(":", "-"), dotted = TRUE) {
  hex <- "[0-9A-Fa-f]"
  alternatives <- character()
  if (length(sep) > 0) {
    sep_class <- paste0("[", paste0("\\", sep, collapse = ""), "]")
    alternatives <- sprintf("%1$s{2}(%2$s)(?:%1$s{2}\\1){4}%1$s{2}",
                            hex, sep_class)
  }
  if (dotted) {
    alternatives <- c(alternatives, sprintf("%1$s{4}\\.%1$s{4}\\.%1$s{4}", hex))
  }
  sprintf("(?<!%1$s)(?<!%1$s[:.-])(?:%2$s)(?!%1$s|[:.-]%1$s)",
          hex, paste(alternatives, collapse = "|"))
}
