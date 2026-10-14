# MAC.address

<!-- badges: start -->
[![R-CMD-check](https://github.com/EnriquePH/mac-address/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/EnriquePH/mac-address/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.md)
<!-- badges: end -->

R tools to work with MAC (Media Access Control) addresses:

- list the MAC addresses of the local network interfaces and of the devices
  in the ARP cache (Linux, macOS, Windows),
- extract MAC addresses from free text,
- validate and normalize their notation, check the multicast and locally
  administered bits, generate random addresses and derive IPv6 identifiers,
- identify the manufacturer using the public IEEE OUI registries.

## Installation

```r
# From CRAN (once published)
install.packages("MAC.address")

# Development version, from GitHub
# install.packages("remotes")
remotes::install_github("EnriquePH/mac-address")
```

## Usage

```r
library(MAC.address)

# MAC addresses of this device, named by interface
get_MAC()
#>            enp3s0f1              wlp2s0
#> "9C:5C:8E:27:D8:13" "10:02:B5:39:B7:C3"

# Extract MAC addresses from text (colon, hyphen and Cisco dotted notation)
txt <- "eth0 1c:4c:7e:30:d8:13, wlan0 00-1A-2B-3C-4D-5E, switch 001a.2b3c.4d5f"
search_MAC(txt)
#> [1] "1C:4C:7E:30:D8:13" "00-1A-2B-3C-4D-5E" "001A.2B3C.4D5F"
search_MAC(txt, normalize = TRUE)
#> [1] "1C:4C:7E:30:D8:13" "00:1A:2B:3C:4D:5E" "00:1A:2B:3C:4D:5F"

# Validate and normalize
is_MAC(c("1C:4C:7E:30:D8:13", "1C:4C:7E:30:D8"))
#> [1]  TRUE FALSE
normalize_MAC("1c4c.7e30.d813", sep = "-")
#> [1] "1C-4C-7E-30-D8-13"

# Manufacturer lookup (downloads the IEEE registries once, then uses a cache)
lookup_vendor(get_MAC())
#> [1] "ASUSTek COMPUTER INC." "Intel Corporate"

# Randomized / virtual addresses are locally administered, not IEEE assigned
is_local_MAC("DA:A1:19:00:00:00")
#> [1] TRUE
is_multicast_MAC("01:00:5E:00:00:FB")
#> [1] TRUE

# Devices in the local network (ARP cache) and their manufacturer
arp <- get_arp_table()
arp$vendor <- lookup_vendor(arp$mac)
arp
#>            ip               mac interface        vendor
#> 1 192.168.1.1 D4:61:95:EE:14:71    wlp2s0 zte corporation

# Random locally administered addresses, e.g. for virtual machines
set.seed(1)
random_MAC(2)
#> [1] "FA:80:D6:D1:E0:69" "42:A1:2A:BA:54:B5"

# IPv6 link-local address derived from a MAC (modified EUI-64)
eui64_MAC("1C:4C:7E:30:D8:13", link_local = TRUE)
#> [1] "fe80::1e4c:7eff:fe30:d813"
```

## Functions

| Function             | Description                                                    |
|----------------------|----------------------------------------------------------------|
| `get_MAC()`          | MAC addresses of the local network interfaces                  |
| `get_arp_table()`    | IP and MAC addresses of the neighbors in the ARP cache         |
| `search_MAC()`       | Extract MAC addresses from text                                |
| `is_MAC()`           | Check whether strings are valid MAC addresses                  |
| `normalize_MAC()`    | Convert to a common notation (`XX:XX:XX:XX:XX:XX` by default)  |
| `is_local_MAC()`     | Check the locally administered bit                             |
| `is_multicast_MAC()` | Check the multicast (group) bit                                |
| `random_MAC()`       | Generate random (by default locally administered) addresses    |
| `eui64_MAC()`        | IPv6 modified EUI-64 identifier and link-local address         |
| `get_oui_registry()` | Download (and cache) the IEEE MA-L, MA-M and MA-S registries   |
| `lookup_vendor()`    | Organization that owns each MAC address block                  |

## Development

Documentation is written with [roxygen2](https://roxygen2.r-lib.org/)
comments in `R/` (Markdown enabled). Never edit `man/` or `NAMESPACE` by hand:

```r
devtools::document()   # regenerate man/ and NAMESPACE
devtools::test()       # run the tests
devtools::check()      # full R CMD check
```

Code style is checked with [lintr](https://lintr.r-lib.org/), configured in
`.lintr` (function names like `get_MAC()` are allowed). Load the package first,
so that functions defined in other files are recognized:

```r
devtools::load_all()
lintr::lint_package()
```

## References

- IEEE Registration Authority: <https://regauth.standards.ieee.org/standards-ra-web/pub/view.html#registries>
- MA-L (OUI) registry: <https://standards-oui.ieee.org/oui/oui.csv>
- MA-M registry: <https://standards-oui.ieee.org/oui28/mam.csv>
- MA-S registry: <https://standards-oui.ieee.org/oui36/oui36.csv>
- RFC 4291, appendix A (modified EUI-64): <https://www.rfc-editor.org/rfc/rfc4291#appendix-A>

## License

MIT © Enrique Pérez Herrero
