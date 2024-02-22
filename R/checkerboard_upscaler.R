#' @export

checkerboard_upscale <- function(data, unsplit_cols = NULL, imputation_method = "linear_regression",
                                 checkerboard = TRUE, uniq_threshold = 5) {

  n_obs <- nrow(data)

  # Prepare output dataframes
  upscaled_data <- data.frame(matrix(nrow = 2 * n_obs, ncol = ncol(data)))
  non_cb_data <- data.frame(matrix(nrow = 0, ncol = ncol(data)))
  colnames(upscaled_data) <- colnames(non_cb_data) <- colnames(data)

  # Detect columns for not splitting
  unsplit_cols <- unique(c(
    unsplit_cols,  # User-provided
    colnames(data)[sapply(data, is.numeric) == FALSE],  # Non-numeric
    colnames(data)[sapply(data, function(x) length(unique(x))) <= uniq_threshold]  # Low variability
  ))
  unsplit_cols <- unsplit_cols[unsplit_cols %in% colnames(data)] # Ensure validity

  # Main loop
  for (i in 1:n_obs) {
    # Copy unsplit columns directly
    upscaled_data[2 * i - 1, unsplit_cols] <- data[i, unsplit_cols]
    upscaled_data[2 * i, unsplit_cols] <- data[i, unsplit_cols]

    # Split columns for imputation
    split_cols <- setdiff(colnames(data), unsplit_cols)
    predictions <- numeric(length(split_cols))

    for (j in seq_along(split_cols)) {
      col_name <- split_cols[j]
      col_idx <- which(colnames(data) == col_name)

      split_data <- data[-i, ]
      other_cols <- setdiff(colnames(split_data), col_name) # Potentially more efficient
      formula <- as.formula(paste(col_name, "~ . -", col_name))

      if (imputation_method == "linear_regression") {
        model <- lm(formula, data = split_data)
        predictions[j] <- predict(model, newdata = data[i, other_cols])

      } else if (imputation_method == "random_forest") {
        model <- randomForest(formula, data = split_data)
        predictions[j] <- predict(model, newdata = data[i, other_cols])

      } else if (imputation_method == "bayesian") {

         # Bayesian linear regression with weakly informative priors
         brm_model <- brm(formula, data = split_data,
                          prior = c(set_prior("normal(0, 10)", class = "Intercept"),
                                    set_prior("normal(0, 5)", class = "b")),
                          seed = i)  # Set a seed for reproducibility

         # Generate prediction (mean of posterior predictive distribution)
         predictions[j] <- mean(posterior_predict(brm_model, newdata = data[i, other_cols]))

      } else {
        stop("Invalid imputation_method.")
      }
    }

    # Conditional Interweaving / Upscaling
    if (checkerboard) {
      # Interweave the rows for output
      split_cols_idx <- which(colnames(data) %in% split_cols)
      for (j in seq_along(split_cols)) {
        col_idx <- split_cols_idx[j]
        upscaled_data[2 * i - 1, col_idx] <- ifelse(j %% 2 == 1, data[i, col_idx], predictions[j])
        upscaled_data[2 * i, col_idx] <- ifelse(j %% 2 == 0, data[i, col_idx], predictions[j])
      }

    } else {
      upscaled_row <- data[i, ]
      upscaled_row[split_cols] <- predictions
      non_cb_data <- rbind(non_cb_data, upscaled_row)
    }
  }

  if (checkerboard) {
    upscaled_data
  } else {
    non_cb_data
  }
}
