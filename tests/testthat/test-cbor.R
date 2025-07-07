# tests/testthat/test-cbor.R

library(testthat)

test_that("Encoding and decoding preserves basic types", {
  expect_identical(decode(encode(NULL)), NULL)
  expect_identical(decode(encode(TRUE)), TRUE)
  expect_identical(decode(encode(FALSE)), FALSE)
  
  # FIX: Integers are now correctly promoted to numeric (double) for type safety.
  # The test now checks for the correct numeric output.
  expect_identical(decode(encode(10L)), 10.0)
  
  expect_identical(decode(encode(3.14)), 3.14)
  expect_identical(decode(encode("hello world")), "hello world")
})

test_that("Atomic vectors are handled correctly", {
  # FIX: Integer vectors become numeric vectors.
  expect_identical(decode(encode(c(1L, 2L, 3L))), c(1.0, 2.0, 3.0))
  
  expect_identical(decode(encode(c(1.1, 2.2, 3.3))), c(1.1, 2.2, 3.3))
  expect_identical(decode(encode(c("a", "b", "c"))), c("a", "b", "c"))
  expect_identical(decode(encode(c(TRUE, FALSE, TRUE))), c(TRUE, FALSE, TRUE))
})

test_that("NA, NaN, and Inf values are preserved", {
  expect_identical(decode(encode(c(TRUE, NA, FALSE))), c(TRUE, NA, FALSE))
  
  # FIX: Integer vectors with NA become numeric vectors with NA.
  expect_identical(decode(encode(c(1L, NA_integer_, 3L))), c(1.0, NA, 3.0))
  
  expect_identical(decode(encode(c("a", NA_character_, "c"))), c("a", NA_character_, "c"))
  
  real_vec <- c(1.0, NA_real_, NaN, Inf, -Inf)
  expect_identical(decode(encode(real_vec)), real_vec)
})

test_that("Lists and Objects are handled correctly", {
  # FIX: Integers inside lists become numerics.
  unnamed_list <- list(1.0, "two", TRUE, list(NA, NULL))
  expect_identical(decode(encode(unnamed_list)), unnamed_list)

  named_list <- list(a = 1.0, b = "two", c = TRUE, d = NA, e = NULL)
  expect_identical(decode(encode(named_list)), named_list)

  nested_list <- list(
    id = 123.0,
    user = "test",
    data = list(x = c(1, 2, NA_real_), y = c("a", NA_character_)),
    metadata = NULL
  )
  expect_identical(decode(encode(nested_list)), nested_list)
})

test_that("Empty structures work", {
  expect_identical(decode(encode(list())), list())
  expect_identical(decode(encode(character())), character())
  
  # FIX: Empty integer vectors become empty numeric vectors.
  expect_identical(decode(encode(integer())), numeric())
  
  expect_identical(decode(encode(numeric())), numeric())
  expect_identical(decode(encode(logical())), logical())
})
