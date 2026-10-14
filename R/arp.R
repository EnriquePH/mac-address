#' Get the ARP table of this device
#'
#' Lists the IPv4 neighbors (other devices in the local network) that this
#' machine has recently talked to, with their MAC addresses, as stored in the
#' operating system ARP cache. Combined with [lookup_vendor()], it helps to
#' identify the devices in a network.
#'
#' Works on Linux (reads `/proc/net/arp`), macOS and other Unix systems
#' (parses `arp -an`) and Windows (parses `arp -a`). Only the existing cache is
#' read: no packets are sent, so devices that have not communicated with this
#' machine recently are not listed.
#'
#' @return A data frame with columns `ip`, `mac` (normalized, see
#'   [normalize_MAC()]) and `interface` (on Windows, the IP address of the
#'   interface). Incomplete entries are dropped. If the table cannot be read,
#'   a warning is given and a data frame with no rows is returned.
#' @seealso [get_MAC()] for the addresses of this device.
#' @export
#'
#' @examples
#' arp <- get_arp_table()
#' head(arp)
#'
#' \donttest{
#' # Manufacturer of each neighbor (needs an internet connection once)
#' oui <- try(get_oui_registry(cache_dir = tempdir()))
#' if (is.data.frame(oui)) arp$vendor <- lookup_vendor(arp$mac, oui)
#' }
get_arp_table <- function() {
  tab <- if (get_os() == "Windows") {
    parse_arp_windows(run_command("arp", "-a"))
  } else if (file.exists("/proc/net/arp")) {
    parse_proc_arp(readLines("/proc/net/arp", warn = FALSE))
  } else {
    parse_arp_unix(run_command("arp", "-an"))
  }

  tab$mac <- normalize_MAC(pad_octets(tab$mac))
  tab <- tab[!is.na(tab$mac) & tab$mac != "00:00:00:00:00:00", ]
  rownames(tab) <- NULL
  tab
}

#' ARP table data frame
#' @noRd
arp_frame <- function(ip = character(), mac = character(),
                      interface = character()) {
  data.frame(ip = ip, mac = mac, interface = interface,
             stringsAsFactors = FALSE)
}

#' Parse `/proc/net/arp` (Linux)
#'
#' Columns: IP address, HW type, Flags, HW address, Mask, Device.
#' @noRd
parse_proc_arp <- function(lines) {
  fields <- strsplit(trimws(lines[-1]), "[[:space:]]+")
  fields <- fields[lengths(fields) >= 6]
  arp_frame(
    ip = vapply(fields, `[`, character(1), 1),
    mac = vapply(fields, `[`, character(1), 4),
    interface = vapply(fields, `[`, character(1), 6)
  )
}

#' Parse `arp -an` (macOS, BSD and Linux net-tools)
#'
#' macOS: `? (192.168.1.1) at 0:11:22:33:44:55 on en0 ifscope [ethernet]`
#' Linux: `? (192.168.1.1) at 00:11:22:33:44:55 [ether] on eth0`
#' @noRd
parse_arp_unix <- function(lines) {
  pattern <- "\\(([^)]+)\\) at ([0-9A-Fa-f:]+)(?:.*? on ([^[:space:]]+))?"
  m <- regmatches(lines, regexec(pattern, lines, perl = TRUE))
  m <- m[lengths(m) == 4]
  arp_frame(
    ip = vapply(m, `[`, character(1), 2),
    mac = vapply(m, `[`, character(1), 3),
    interface = vapply(m, `[`, character(1), 4)
  )
}

#' Parse `arp -a` (Windows)
#'
#' Blocks start with `Interface: 192.168.1.5 --- 0xb`, followed by lines like
#' `  192.168.1.1           00-11-22-33-44-55     dynamic`.
#' @noRd
parse_arp_windows <- function(lines) {
  rows <- list()
  iface <- NA_character_
  for (line in lines) {
    head <- regmatches(line, regexec("^[^[:space:]].*?: ([0-9.]+) ---", line))
    if (length(head[[1]]) == 2) {
      iface <- head[[1]][2]
      next
    }
    entry <- regmatches(line, regexec(
      "^[[:space:]]+([0-9.]+)[[:space:]]+([0-9A-Fa-f-]{17})[[:space:]]", line
    ))[[1]]
    if (length(entry) == 3) rows[[length(rows) + 1]] <- c(entry[2:3], iface)
  }
  if (length(rows) == 0) return(arp_frame())
  rows <- do.call(rbind, rows)
  arp_frame(ip = rows[, 1], mac = rows[, 2], interface = rows[, 3])
}

#' Add leading zeros to octets, as macOS prints `0:1a:2:...`
#' @noRd
pad_octets <- function(mac) {
  short <- grepl("^([0-9A-Fa-f]{1,2}:){5}[0-9A-Fa-f]{1,2}$", mac)
  mac[short] <- gsub("(^|:)([0-9A-Fa-f])(?=:|$)", "\\10\\2", mac[short],
                     perl = TRUE)
  mac
}
