# tests/testthat/test-cbor.R

library(testthat)

# The context() function was deprecated in testthat 3rd edition.

test_that("Encoding and decoding preserves basic types", {
  expect_identical(decode_cbor(encode_cbor(NULL)), NULL)
  expect_identical(decode_cbor(encode_cbor(TRUE)), TRUE)
  expect_identical(decode_cbor(encode_cbor(FALSE)), FALSE)
  expect_identical(decode_cbor(encode_cbor(10L)), 10L)
  expect_identical(decode_cbor(encode_cbor(3.14)), 3.14)
  expect_identical(decode_cbor(encode_cbor("hello world")), "hello world")
})

test_that("Atomic vectors are handled correctly", {
  expect_identical(decode_cbor(encode_cbor(c(1L, 2L, 3L))), c(1L, 2L, 3L))
  expect_identical(decode_cbor(encode_cbor(c(1.1, 2.2, 3.3))), c(1.1, 2.2, 3.3))
  expect_identical(decode_cbor(encode_cbor(c("a", "b", "c"))), c("a", "b", "c"))
  expect_identical(decode_cbor(encode_cbor(c(TRUE, FALSE, TRUE))), c(TRUE, FALSE, TRUE))
})

test_that("NA, NaN, and Inf values are preserved", {
  # Logical NA
  expect_identical(decode_cbor(encode_cbor(c(TRUE, NA, FALSE))), c(TRUE, NA, FALSE))
  # Integer NA
  expect_identical(decode_cbor(encode_cbor(c(1L, NA_integer_, 3L))), c(1L, NA_integer_, 3L))
  # Character NA
  expect_identical(decode_cbor(encode_cbor(c("a", NA_character_, "c"))), c("a", NA_character_, "c"))
  # Real NA, NaN, Inf
  real_vec <- c(1.0, NA_real_, NaN, Inf, -Inf)
  expect_identical(decode_cbor(encode_cbor(real_vec)), real_vec)
})


test_that("Lists and Objects are handled correctly", {
  # Unnamed list (becomes an array)
  unnamed_list <- list(1, "two", TRUE, list(NA, NULL))
  expect_identical(decode_cbor(encode_cbor(unnamed_list)), unnamed_list)

  # Named list (becomes an object)
  named_list <- list(a = 1, b = "two", c = TRUE, d = NA, e = NULL)
  expect_identical(decode_cbor(encode_cbor(named_list)), named_list)

  # Nested list
  nested_list <- list(
    id = 123,
    user = "test",
    data = list(x = c(1,2, NA_integer_), y = c("a", NA_character_)),
    metadata = NULL
  )
  expect_identical(decode_cbor(encode_cbor(nested_list)), nested_list)
})

test_that("Empty structures work", {
  expect_identical(decode_cbor(encode_cbor(list())), list())
  expect_identical(decode_cbor(encode_cbor(character())), character())
  expect_identical(decode_cbor(encode_cbor(integer())), integer())
  expect_identical(decode_cbor(encode_cbor(numeric())), numeric())
  expect_identical(decode_cbor(encode_cbor(logical())), logical())
})
