# Generated by extendr: Do not edit by hand

# nolint start

#
# This file was created with the following call:
#   .Call("wrap__make_RCBOR_wrappers", use_symbols = TRUE, package_name = "RCBOR")

#' @usage NULL
#' @useDynLib RCBOR, .registration = TRUE
NULL

#' Encode an R object into a CBOR byte vector
#'
#' This function takes an R object and serializes it into a `raw` vector
#' representing the object in CBOR format. It supports most common R data
#' types, including atomic vectors, lists, and `NULL`.
#'
#' @param x The R object to encode.
#' @return A `raw` vector containing the CBOR representation of the object.
#' @examples
#' # Encode a simple integer
#' raw_bytes <- encode(123L)
#'
#' # Encode a named list
#' my_list <- list(a = 1, b = "hello", c = c(TRUE, FALSE, NA))
#' encoded_list <- encode(my_list)
#'
#' # The output is a raw vector
#' class(encoded_list)
#'
#' @export
encode <- function(x) .Call(wrap__encode, x)

#' Decode a CBOR byte vector into an R object
#'
#' This function takes a `raw` vector of bytes and deserializes it back
#' into an R object, assuming the bytes are in valid CBOR format.
#'
#' @param bytes A `raw` vector of CBOR bytes.
#' @return The decoded R object.
#' @examples
#' # Create a CBOR byte string (e.g., from an external source or `encode`)
#' encoded_obj <- encode(list(id = 42, user = "test"))
#'
#' # Decode it back to an R object
#' decoded_obj <- decode(encoded_obj)
#'
#' # Verify the structure
#' str(decoded_obj)
#'
#' @export
decode <- function(bytes) .Call(wrap__decode, bytes)


# nolint end
