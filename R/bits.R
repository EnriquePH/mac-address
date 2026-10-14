#' Check whether MAC addresses are locally administered
#'
#' Locally administered addresses (e.g. randomized addresses used by phones
#' for Wi-Fi privacy, or virtual machines) have the second least significant
#' bit of the first octet set (the U/L bit).
#'
#' @param mac A character vector of MAC addresses.
#'
#' @return A logical vector (`NA` for invalid addresses).
#' @seealso [is_multicast_MAC()], [random_MAC()]
#' @export
#'
#' @examples
#' is_local_MAC(c("02:00:00:00:00:01", "1C:4C:7E:30:D8:13"))
is_local_MAC <- function(mac) {
  bitwAnd(first_octet(mac), 2L) > 0
}

#' Check whether MAC addresses are multicast
#'
#' Multicast (group) addresses have the least significant bit of the first
#' octet set (the I/G bit). The broadcast address `FF:FF:FF:FF:FF:FF` is a
#' multicast address. Network interfaces always have unicast addresses.
#'
#' @inheritParams is_local_MAC
#'
#' @return A logical vector (`NA` for invalid addresses).
#' @seealso [is_local_MAC()]
#' @export
#'
#' @examples
#' is_multicast_MAC(c("01:00:5E:00:00:FB", "FF:FF:FF:FF:FF:FF",
#'                    "1C:4C:7E:30:D8:13"))
is_multicast_MAC <- function(mac) {
  bitwAnd(first_octet(mac), 1L) > 0
}

#' First octet of MAC addresses, as an integer
#' @noRd
first_octet <- function(mac) {
  strtoi(substr(normalize_MAC(mac), 1, 2), base = 16)
}

#' Generate random MAC addresses
#'
#' Generates random MAC addresses, e.g. for virtual machines, containers or
#' tests. By default they are locally administered unicast addresses, so they
#' never clash with addresses assigned by the IEEE to manufacturers. Uses R's
#' random number generator, so results can be reproduced with [set.seed()].
#'
#' @param n Number of addresses.
#' @param local Logical. Set the locally administered bit (see
#'   [is_local_MAC()])? If `FALSE`, the bit is cleared.
#' @param multicast Logical. Set the multicast bit (see [is_multicast_MAC()])?
#' @param sep Separator to use, as in [normalize_MAC()].
#'
#' @return A character vector of `n` MAC addresses.
#' @export
#'
#' @examples
#' set.seed(1)
#' random_MAC(3)
#' random_MAC(1, sep = "-")
random_MAC <- function(n = 1, local = TRUE, multicast = FALSE, sep = ":") {
  stopifnot(length(n) == 1, !is.na(n), n >= 0, n == round(n),
            is.logical(local), is.logical(multicast))
  bytes <- matrix(sample.int(256L, 6L * n, replace = TRUE) - 1L, ncol = 6)
  first <- bitwAnd(bytes[, 1], 0xFCL)
  if (isTRUE(local)) first <- bitwOr(first, 2L)
  if (isTRUE(multicast)) first <- bitwOr(first, 1L)
  bytes[, 1] <- first
  stopifnot(is.character(sep), length(sep) == 1, !is.na(sep))
  out <- apply(bytes, 1, function(b) paste(sprintf("%02X", b), collapse = sep))
  as.character(out)
}

#' Modified EUI-64 interface identifier of MAC addresses
#'
#' Derives the IPv6 interface identifier from a MAC address, as used by
#' stateless address autoconfiguration (RFC 4291, appendix A): `FF:FE` is
#' inserted in the middle of the address and the U/L bit is inverted.
#'
#' @inheritParams is_local_MAC
#' @param link_local Logical. If `TRUE`, return the IPv6 link-local address
#'   (`fe80::/64` prefix) instead of the interface identifier alone.
#'
#' @return A character vector in IPv6 notation (lower case, leading zeros
#'   omitted, as recommended by RFC 5952). `NA` for invalid addresses.
#' @export
#'
#' @examples
#' eui64_MAC("1C:4C:7E:30:D8:13")
#' eui64_MAC("1C:4C:7E:30:D8:13", link_local = TRUE)
eui64_MAC <- function(mac, link_local = FALSE) {
  if (length(mac) == 0) return(character())
  hex <- tolower(normalize_MAC(mac, sep = ""))
  first <- sprintf("%02x", bitwXor(first_octet(mac), 2L))
  eui <- paste0(first, substr(hex, 3, 6), "fffe", substr(hex, 7, 12))
  groups <- vapply(seq(1, 13, 4), function(i) {
    sub("^0+(?=.)", "", substr(eui, i, i + 3), perl = TRUE)
  }, character(length(eui)))
  out <- apply(matrix(groups, nrow = length(eui)), 1, paste, collapse = ":")
  out <- as.character(out)
  if (link_local) out <- paste0("fe80::", out)
  out[is.na(hex)] <- NA_character_
  out
}
