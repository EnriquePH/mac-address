# Tests need the suggested package 'testthat'; skip them if it is missing
if (requireNamespace("testthat", quietly = TRUE)) {
  library(testthat)
  library(MAC.address)

  test_check("MAC.address")
}
