#' @export

s_weighted_bootstrap <- function(shadow_results, num_bootstraps, refit_model = TRUE, conf_level = 0.95) {

  # 1. Extract Information
  original_data <- shadow_results$original_dataset
  model_formula <- shadow_results$model_formula # Extract model formula

  # 2. Bootstrap Loop
  num_coefs <- length(model_formula$coefficients)  # Number of coefficients to store
  bootstrap_coefs <- list()

  for (i in 1:num_bootstraps) {

    # Sample with Weighted Probability
    bootstrap_idx <- sample(nrow(original_data), size = nrow(original_data),
                            replace = TRUE, prob = original_data$obs_weight)
    bootstrap_data <- original_data[bootstrap_idx, ]

    # Refit Model (If refit_model is TRUE)
    if (refit_model) {
      bootstrap_model <- lm(model_formula, data = bootstrap_data)
      bootstrap_coefs[[i]] <- coef(bootstrap_model)

    }

  }

  # 3. Calculate mean and quantiles with custom conf_level
  coef_means <- colMeans(do.call(rbind, bootstrap_coefs))
  alpha <- 1 - conf_level  # for calculating appropriate tail regions
  coef_lower <- apply(do.call(rbind, bootstrap_coefs), 2, quantile, probs = alpha / 2)
  coef_upper <- apply(do.call(rbind, bootstrap_coefs), 2, quantile, probs = 1 - alpha / 2)

  # 4. Prepare Descriptive Statements
  model_formula_str <- deparse(shadow_results$model_formula) # Convert formula for printing
  technique <- "Probability Bundled Bootstrapping"
  confidence_percentage <- round(conf_level * 100)  # For neat display

  # 5. Create Data Frame for Table Output
  coef_names <- names(coef_means)
  output_df <- data.frame(Lower = coef_lower,
                          Upper = coef_upper)

  # 6. Print Output
  cat("Model Formula:", model_formula_str, "\n\n")  # Print formula
  cat("   ",confidence_percentage, "% Weighted Bootstrap Confidence Intervals\n")
  print(output_df)                            # Print the table

  # 7. Return (Optional)
  # return(output_df)
}

