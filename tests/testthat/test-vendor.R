fake_registry <- data.frame(
  registry = c("MA-L", "MA-L", "MA-M", "MA-S"),
  assignment = c("00000C", "1C4C7E", "1C4C7E3", "1C4C7E30D"),
  organization = c("Cisco", "Large Co", "Medium Co", "Small Co"),
  address = "",
  stringsAsFactors = FALSE
)

test_that("lookup_vendor uses the longest matching prefix", {
  expect_equal(
    lookup_vendor(
      c("00-00-0C-12-34-56", "1C:4C:7E:30:D8:13", "1C:4C:7E:31:00:00",
        "1C:4C:7E:FF:00:00", "AA:BB:CC:DD:EE:FF", "bad"),
      registry = fake_registry
    ),
    c("Cisco", "Small Co", "Medium Co", "Large Co", NA, NA)
  )
})

test_that("lookup_vendor accepts lower case prefixes and checks the registry", {
  reg <- data.frame(assignment = "1c4c7e", organization = "Large Co")
  expect_equal(lookup_vendor("1C:4C:7E:30:D8:13", reg), "Large Co")
  expect_equal(lookup_vendor(character(), reg), character())
  expect_error(lookup_vendor("1C:4C:7E:30:D8:13", data.frame(x = 1)),
               "registry")
})

test_that("get_oui_registry reads the IEEE registry", {
  skip_on_cran()
  skip_if_offline("standards-oui.ieee.org")
  oui <- tryCatch(
    suppressMessages(
      get_oui_registry("MA-L", cache_dir = withr::local_tempdir())
    ),
    error = function(e) skip(conditionMessage(e))
  )
  expect_named(oui, c("registry", "assignment", "organization", "address"))
  expect_equal(lookup_vendor("00:00:0C:00:00:00", oui), "Cisco Systems, Inc")
})
