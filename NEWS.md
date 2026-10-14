# MAC.address 0.1.0

* `get_MAC()` now works on Linux, macOS and Windows and returns a named vector
  of addresses per interface, instead of the raw `ifconfig` output.
* `search_MAC()` supports hyphen and Cisco dotted notation, requires a
  consistent separator inside each address and no longer matches pieces of
  longer hexadecimal strings. New `normalize` and `unique` arguments.
* New `normalize_MAC()`, `is_MAC()` and `is_local_MAC()`.
* New `get_oui_registry()` and `lookup_vendor()` to identify the manufacturer
  using the IEEE MA-L, MA-M and MA-S registries.
* New `get_arp_table()`: IP and MAC addresses of the neighbors in the ARP
  cache (Linux, macOS, Windows).
* New `is_multicast_MAC()`, `random_MAC()` and `eui64_MAC()` (IPv6 modified
  EUI-64 identifier and link-local address).
* `search_MAC(sep = character())` searches only the Cisco dotted notation.
* Removed the `magrittr` and `stringr` dependencies.
* First CRAN release.
