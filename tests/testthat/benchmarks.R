library(bench)

# (1) Defining the complex data object that will be used for testing
# This attempts to simulates a potential data structure from a bioinformatics experiment
complex_data <- list(
  run_id = "EXP-2024-07-04-A",
  instrument_params = list(
    type = "GC-MS",
    ionization = "EI",
    mass_range = c(50L, 550L)
  ),
  samples = replicate(100, {
    list(
      id = paste0(sample(LETTERS, 8, replace = TRUE), collapse = ""),
      value = runif(1, 50, 200),
      is_qc = sample(c(TRUE, FALSE), 1)
    )
  }, simplify = FALSE),
  qc_passed = TRUE,
  comment = "Run completed under standard conditions."
)

# (2) Runs the benchmark
# We use `press()` in order to run each expression multiple times and attempt to get reliable timing.
benchmark_results <- press(
  object = complex_data,
  {
    mark(
      # Our RCBOR package
      rcbor_encode = RCBOR::encode(object),
      rcbor_decode = {
        encoded <- RCBOR::encode(object)
        RCBOR::decode(encoded)
      },

      # Comparison with JSON
      jsonlite_encode = jsonlite::toJSON(object, auto_unbox = TRUE),
      jsonlite_decode = {
        encoded <- jsonlite::toJSON(object, auto_unbox = TRUE)
        jsonlite::fromJSON(encoded)
      },

      # Comparison with R's native binary format
      # REMINDER: The `connection = NULL` argument tells `serialize` to return a raw vector.
      rds_serialize = serialize(object, connection = NULL),
      rds_unserialize = {
        encoded <- serialize(object, connection = NULL)
        unserialize(encoded)
      },
      min_iterations = 50, # Run each at least 50 times
      check = FALSE # Disable return value checking
    )
  }
)

# (2) Print/return results
# This should show a table with timings, memory usage, and performance relative to the fastest method.
print(benchmark_results)

# Could also generate a plot of results with...
# plot(benchmark_results)
