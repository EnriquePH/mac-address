test_that("search_MAC finds colon, hyphen and dotted notations", {
  txt <- "a 1C:4C:7E:30:d8:13 b 00-1a-2b-3c-4d-5e c 001a.2b3c.4d5f"
  expect_equal(
    search_MAC(txt),
    c("1C:4C:7E:30:D8:13", "00-1A-2B-3C-4D-5E", "001A.2B3C.4D5F")
  )
  expect_equal(search_MAC(txt, dotted = FALSE), search_MAC(txt)[1:2])
  expect_equal(search_MAC(txt, sep = ":", dotted = FALSE), "1C:4C:7E:30:D8:13")
})

test_that("search_MAC normalizes and removes duplicates", {
  txt <- "1c:4c:7e:30:d8:13 and 1C-4C-7E-30-D8-13"
  expect_equal(
    search_MAC(txt, normalize = TRUE, unique = TRUE),
    "1C:4C:7E:30:D8:13"
  )
})

test_that("search_MAC rejects mixed separators and longer hex sequences", {
  expect_length(search_MAC("1C:4C-7E:30:D8:13"), 0)
  expect_length(search_MAC("1C:4C:7E:30:D8:13:AA:BB"), 0)  # EUI-64
  expect_length(search_MAC("AA1C:4C:7E:30:D8:13"), 0)
  expect_equal(search_MAC("MAC=1C:4C:7E:30:D8:13."), "1C:4C:7E:30:D8:13")
})

test_that("search_MAC handles empty input", {
  expect_equal(search_MAC(character()), character())
  expect_equal(search_MAC("no addresses here"), character())
})

test_that("is_MAC validates whole strings", {
  expect_equal(
    is_MAC(c("1C:4C:7E:30:D8:13", "1c4c.7e30.d813", "1C:4C:7E:30:D8",
             "x1C:4C:7E:30:D8:13", NA)),
    c(TRUE, TRUE, FALSE, FALSE, FALSE)
  )
})

test_that("normalize_MAC converts notations", {
  expect_equal(
    normalize_MAC(c("1c-4c-7e-30-d8-13", "1c4c.7e30.d813", "bad", NA)),
    c("1C:4C:7E:30:D8:13", "1C:4C:7E:30:D8:13", NA, NA)
  )
  expect_equal(normalize_MAC("1C:4C:7E:30:D8:13", sep = ""), "1C4C7E30D813")
  expect_equal(normalize_MAC(character()), character())
})

test_that("search_MAC can search only the dotted notation", {
  txt <- "1C:4C:7E:30:D8:13 001a.2b3c.4d5f"
  expect_equal(search_MAC(txt, sep = character()), "001A.2B3C.4D5F")
  expect_error(search_MAC(txt, sep = character(), dotted = FALSE))
})

test_that("normalize_MAC checks its separator", {
  expect_error(normalize_MAC("1C:4C:7E:30:D8:13", sep = c(":", "-")))
})
