#' @export

fidelity_error_index <- function(data, n_iterations = 10, subsample_size = 0.5,
                           imputation_method = "linear_regression",
                           comparison_metric = "mean_squared_error") {

  # Identify numeric and non-numeric columns
  numeric_cols <- sapply(data, is.numeric)
  non_numeric_cols <- !numeric_cols

  # Initialize storage for results
  results <- list() # To store both types of results
  column_mse_means <- matrix(0, nrow = n_iterations, ncol = ncol(data[numeric_cols]))
  original_column_sds <- apply(data[numeric_cols], 2, sd)
  output <- list()

  # Main iteration loop
  for (i in 1:n_iterations) {
    # Random subsampling
    subsample_idx <- sample(nrow(data), round(subsample_size * nrow(data)))
    subsampled_data <- data[subsample_idx, ]


    # Upscaling
    print(paste0("Iteration ", i, ": upscaling..."))
    upscaled_data <- checkerboard_upscale(subsampled_data,
                                          unsplit_cols = names(data)[non_numeric_cols],
                                          imputation_method = imputation_method)

    # Calculate comparison metric
    if (comparison_metric == "mean_squared_error") {

      # Adjust upscaled_data size to match original
      if (nrow(upscaled_data) > nrow(data)) {
        upscaled_data <- upscaled_data[-sample(1:nrow(upscaled_data), 1), ]
      }

      mse <- colMeans((data[, numeric_cols] - upscaled_data[, numeric_cols])^2)
      normalized_mse <- sqrt(mse) / original_column_sds
      overall_mse <- mean(normalized_mse)

      column_mse_means[i, ] <- normalized_mse
      results[[i]] <- list(column_wise_mse = normalized_mse, overall_mse = overall_mse)

    } else {

      # If you have a custom comparison function:
    }
  }

  # Calculate overall fidelity index
  overall_mse_values <- sapply(results, function(x) x$overall_mse)
  mean_fidelity_error_index <- mean(overall_mse_values)

  #
  mean_mse_per_column <- colMeans(column_mse_means)

  # Add column names to output
  output <- list(mean_fidelity_error_index = mean_fidelity_error_index,
                 mean_error_index_per_column = data.frame(column = names(data)[numeric_cols],
                                             mse_per_column = mean_mse_per_column))
  print(paste0("Mean fidelity error index: ", mean_fidelity_error_index))
  return(output)
}
