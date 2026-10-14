test_that("get_MAC returns normalized addresses named by interface", {
  macs <- get_MAC()
  expect_type(macs, "character")
  expect_true(all(is_MAC(macs)))
  expect_false("00:00:00:00:00:00" %in% macs)
  if (length(macs) > 0) expect_false(is.null(names(macs)))
})

test_that("parse_ifconfig reads macOS and Linux ifconfig output", {
  macos <- c(
    "lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384",
    "\tinet 127.0.0.1 netmask 0xff000000",
    "en0: flags=8863<UP,BROADCAST,SMART,RUNNING> mtu 1500",
    "\tether 1c:4c:7e:30:d8:13",
    "\tinet6 fe80::1c4c:7eff:fe30:d813%en0 prefixlen 64"
  )
  expect_equal(parse_ifconfig(macos), c(en0 = "1C:4C:7E:30:D8:13"))

  linux <- c(
    "eth0      Link encap:Ethernet  HWaddr 00:1a:2b:3c:4d:5e",
    "          inet addr:192.168.1.2"
  )
  expect_equal(parse_ifconfig(linux), c(eth0 = "00:1A:2B:3C:4D:5E"))
})

test_that("parse_getmac reads Windows getmac CSV output", {
  out <- c(
    "",
    '"Ethernet","Intel(R) Ethernet","1C-4C-7E-30-D8-13","\\Device\\Tcpip_{X}"',
    '"Wi-Fi","Intel(R) Wireless","00-1A-2B-3C-4D-5E","Media disconnected"'
  )
  expect_equal(
    parse_getmac(out),
    c(Ethernet = "1C-4C-7E-30-D8-13", `Wi-Fi` = "00-1A-2B-3C-4D-5E")
  )
  expect_equal(parse_getmac(character()), character())
})
