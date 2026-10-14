test_that("is_local_MAC checks the locally administered bit", {
  expect_equal(
    is_local_MAC(c("02:00:00:00:00:01", "DA:A1:19:00:00:00",
                   "1C:4C:7E:30:D8:13", "bad")),
    c(TRUE, TRUE, FALSE, NA)
  )
})

test_that("is_multicast_MAC checks the group bit", {
  expect_equal(
    is_multicast_MAC(c("01:00:5E:00:00:FB", "FF:FF:FF:FF:FF:FF",
                       "1C:4C:7E:30:D8:13", "bad")),
    c(TRUE, TRUE, FALSE, NA)
  )
})

test_that("random_MAC generates valid addresses with the requested bits", {
  set.seed(42)
  macs <- random_MAC(100)
  expect_length(macs, 100)
  expect_true(all(is_MAC(macs)))
  expect_true(all(is_local_MAC(macs)))
  expect_false(any(is_multicast_MAC(macs)))

  global <- random_MAC(50, local = FALSE, multicast = TRUE)
  expect_false(any(is_local_MAC(global)))
  expect_true(all(is_multicast_MAC(global)))

  expect_match(random_MAC(1, sep = "-"), "^([0-9A-F]{2}-){5}[0-9A-F]{2}$")
  expect_equal(random_MAC(0), character())
  expect_error(random_MAC(-1))
  set.seed(1)
  a <- random_MAC(2)
  set.seed(1)
  expect_equal(random_MAC(2), a)
})

test_that("eui64_MAC follows RFC 4291", {
  expect_equal(eui64_MAC("1C:4C:7E:30:D8:13"), "1e4c:7eff:fe30:d813")
  expect_equal(
    eui64_MAC(c("02:00:00:00:00:01", "bad"), link_local = TRUE),
    c("fe80::0:ff:fe00:1", NA)
  )
  expect_equal(eui64_MAC("00-1A-2B-3C-4D-5E"), "21a:2bff:fe3c:4d5e")
  expect_equal(eui64_MAC(character()), character())
})
