
[![R-CMD-check](https://github.com/ItsMeForLua/RCBOR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ItsMeForLua/RCBOR/actions/workflows/R-CMD-check.yaml)

<!-- README.md is generated from README.Rmd. Please edit that file -->

# RCBOR: A High-Performance CBOR Toolkit for R

[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
![](https://img.shields.io/badge/Built%20with-Rust-blue.svg)

**RCBOR** provides a fast and efficient bridge between R and the Concise
Binary Object Representation (CBOR) format, as defined in RFC 8949. The
core serialization and deserialization logic is implemented in Rust for
maximum performance and safety, which makes it an ideal choice for
situations where data transfer speed and low overhead are critical. A
common need in bioinformatics and high-throughput data pipelines.

## Why RCBOR?

- **Performance:** By leveraging Rust’s powerful `serde` and `ciborium`
  crates, `RCBOR` significantly outperforms text-based formats like
  JSON, and is impressively memory-efficient.
- **Inter-operability:** CBOR is a standardized format, allowing easy
  data exchange between R and other languages like Python, C++, Java,
  and JavaScript.
- **Simplicity:** The package exposes two primary functions: `encode()`
  and `decode()`, making it straightforward to integrate into any
  workflow.

## Installation

Currently, `RCBOR` is not on CRAN. You can install the development
version from GitHub using `{devtools}`:

``` r
# install.packages("devtools")
devtools::install_github("ItsMeForLua/RCBOR")
```

*(Note: You will need to have a Rust toolchain installed to compile the
package.)*

## Quick-start Example

The workflow is simple: `encode()` an R object into a raw byte vector,
and `decode()` it back.

``` r
library(RCBOR)

# Create a complex R object (e.g., representing experimental results)
original_data <- list(
  sample_id = "BIO-001",
  timestamp = "2024-07-04T18:30:00Z",
  is_control = FALSE,
  measurements = c(10.5, 12.1, NA, 11.8),
  metadata = list(
    instrument = "MassSpec-v2",
    operator = "A. Turing"
  )
)

# 1. Encode the R object into CBOR
encoded_data <- encode(original_data)

# 2. Decode the raw vector back into an R object
decoded_data <- decode(encoded_data)

# 3. Verify that the decoded object is identical to the original
identical(original_data, decoded_data)
```

## Performance

The primary motivation for building `RCBOR` in Rust is performance.
Benchmarks show that it is significantly faster and more
memory-efficient than the commonly used `jsonlite` package for encoding
and decoding complex R objects. For example, here is a comparison using
a nested list with 100 sample records:

| Expression       | Median Time | Memory Allocated | Relative Speed   |
|:-----------------|:------------|:-----------------|:-----------------|
| **rcbor_encode** | **25µs**    | **0B**           | **~6x faster**   |
| jsonlite_encode  | 151µs       | 18.9KB           | 1x (baseline)    |
| **rcbor_decode** | **~73µs**   | **0B**           | **~3.3x faster** |
| jsonlite_decode  | ~242µs      | 12.1KB           | 1x (baseline)    |

Benchmark: RCBOR vs. jsonlite

While R’s native `serialize()` function is faster for R-to-R
communication, its format is not inter-operable with other languages.
`RCBOR` provides the ideal balance of high performance and
cross-platform compatibility. This serialization toolkit enables fast
and reliable data exchange for any R application.
