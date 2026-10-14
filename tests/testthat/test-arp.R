test_that("get_arp_table returns a data frame of neighbors", {
  arp <- get_arp_table()
  expect_s3_class(arp, "data.frame")
  expect_named(arp, c("ip", "mac", "interface"))
  expect_true(all(is_MAC(arp$mac)))
})

test_that("parse_proc_arp reads Linux /proc/net/arp", {
  lines <- c(
    "IP address    HW type  Flags  HW address         Mask  Device",
    "192.168.1.1   0x1      0x2    00:1a:2b:3c:4d:5e  *     wlp2s0",
    "192.168.1.7   0x1      0x0    00:00:00:00:00:00  *     wlp2s0"
  )
  arp <- parse_proc_arp(lines)
  expect_equal(arp$ip, c("192.168.1.1", "192.168.1.7"))
  expect_equal(arp$mac[1], "00:1a:2b:3c:4d:5e")
  expect_equal(arp$interface[1], "wlp2s0")
  expect_equal(nrow(parse_proc_arp(lines[1])), 0)
})

test_that("parse_arp_unix reads macOS and Linux arp -an output", {
  lines <- c(
    "? (192.168.1.1) at 0:1a:2b:3c:4d:5e on en0 ifscope [ethernet]",
    "? (192.168.1.9) at (incomplete) on en0 ifscope [ethernet]",
    "? (10.0.0.1) at 00:1a:2b:3c:4d:5f [ether] on eth0"
  )
  arp <- parse_arp_unix(lines)
  expect_equal(arp$ip, c("192.168.1.1", "10.0.0.1"))
  expect_equal(arp$interface, c("en0", "eth0"))
  expect_equal(normalize_MAC(pad_octets(arp$mac)),
               c("00:1A:2B:3C:4D:5E", "00:1A:2B:3C:4D:5F"))
})

test_that("parse_arp_windows reads arp -a output", {
  lines <- c(
    "",
    "Interface: 192.168.1.5 --- 0xb",
    "  Internet Address      Physical Address      Type",
    "  192.168.1.1           00-1a-2b-3c-4d-5e     dynamic",
    "  192.168.1.255         ff-ff-ff-ff-ff-ff     static",
    "",
    "Interfaz: 10.0.0.2 --- 0x5",
    "  Dirección de Internet  Dirección física      Tipo",
    "  10.0.0.1              00-1a-2b-3c-4d-5f     dinámico"
  )
  arp <- parse_arp_windows(lines)
  expect_equal(arp$ip, c("192.168.1.1", "192.168.1.255", "10.0.0.1"))
  expect_equal(arp$interface, c("192.168.1.5", "192.168.1.5", "10.0.0.2"))
  expect_equal(nrow(parse_arp_windows(character())), 0)
})

test_that("pad_octets adds leading zeros", {
  expect_equal(pad_octets(c("0:1a:2:3c:4d:5", "00:1A:2B:3C:4D:5E")),
               c("00:1a:02:3c:4d:05", "00:1A:2B:3C:4D:5E"))
})
