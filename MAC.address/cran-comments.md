## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

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
* `get_MAC()` only reads local network configuration (`/sys/class/net`,
  `ifconfig` or `getmac`). It does not send any data.
