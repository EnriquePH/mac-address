## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.
* Possibly misspelled words in DESCRIPTION: ARP (Address Resolution
  Protocol), EUI (from EUI-64, Extended Unique Identifier) and IPv (from
  IPv6). They are standard networking terms and are spelled correctly.

## Test environments

* Local: Ubuntu Linux, R 4.5.2 (`R CMD check --as-cran`)
* win-builder: R-devel and R-release
* mac-builder: R-release

## Notes for CRAN

* `get_oui_registry()` downloads the public IEEE registries. It fails with an
  informative error when the resource is not available. Its examples are in
  `\donttest{}`, wrapped in `try()`, and write only to `tempdir()`.
  Tests that need internet access use `skip_on_cran()`.
* The user cache is located with `tools::R_user_dir()`, and is only written
  when the user calls `get_oui_registry()` without a `cache_dir`.
* `get_MAC()` and `get_arp_table()` only read the local network configuration
  (`/sys/class/net`, `/proc/net/arp`, `ifconfig`, `arp` or `getmac`). They do
  not send any packets or data.
* To our knowledge, no other CRAN package provides MAC address parsing or
  IEEE OUI vendor lookup; existing network packages (e.g. 'ipaddress', 'IP')
  work with IP addresses.
