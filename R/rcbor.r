#' @useDynLib RCBOR, .registration = TRUE
NULL

#' A simple hello world from Rust
#'
#' This is a test function to ensure the Rust library is loaded
#' and callable from R.
#' @return A string "Hello world!".
#' @export
rcbor_hello <- function() {
  .Call(wrap__hello_world)
}


#' Encode an R object into a CBOR byte string
#'
#' Serializes an R object into a raw vector representing the object in
#' Concise Binary Object Representation (CBOR) format.
#'
#' The function handles various R object types, including atomic vectors
#' (logical, integer, numeric, character), lists (named and unnamed),
#' and special values like `NULL`, `NA`, `NaN`, and `Inf`.
#'
#' @param x The R object to encode.
#' @return A `raw` vector containing the CBOR representation of the object.
#' @examples
#' # Encode a named list
#' my_list <- list(a = 1, b = "hello", c = c(TRUE, FALSE, NA))
#' encoded_data <- encode_cbor(my_list)
#' print(encoded_data)
#'
#' # Encode a simple vector
#' encoded_vec <- encode_cbor(1:5)
#'
#' @export
encode_cbor <- function(x) {
  .Call(wrap__encode, x)
}

#' Decode a CBOR byte string into an R object
#'
#' Deserializes a raw vector containing CBOR data back into an R object.
#'
#' The function attempts to reconstruct the original R object structure. It
#' intelligently converts CBOR arrays into the most appropriate atomic R vector
#' type (e.g., integer, numeric) if the elements are homogeneous, otherwise it
#' creates a generic list.
#'
#' @param bytes A `raw` vector of CBOR bytes to decode.
#' @return The decoded R object.
#' @examples
#' # Encode and then decode a named list
#' my_list <- list(a = 1, b = "hello", c = c(TRUE, FALSE, NA))
#' encoded_data <- encode_cbor(my_list)
#' decoded_list <- decode_cbor(encoded_data)
#'
#' identical(my_list, decoded_list)
#'
#' @export
decode_cbor <- function(bytes) {
  # Ensure the input is a raw vector
  if (!is.raw(bytes)) {
    stop("Input must be a raw vector.")
  }
  .Call(wrap__decode, bytes)
}
