#' Model Explorer
#'
#' Explores potential linear regression models using different combinations of predictor variables.
#'
#' @param data A data frame containing the variables.
#' @param y The name of the target variable (as a string).
#' @param x1 The name of the first predictor variable (as a string).
#' @param x2 The name of the second predictor variable (as a string).
#' @param x3 The name of the third predictor variable (as a string), optional.
#' @param x4 The name of the fourth predictor variable (as a string), optional.
#' @param x5 The name of the fifth predictor variable (as a string), optional.
#' @param p_value_threshold The p-value threshold for determining statistical significance (default = 0.05).
#'
#' @return A data frame containing the following columns:
#'   - model: The model formula.
#'   - predictors: A list of statistically significant predictors in the model.
#'   - p_values: A list of corresponding p-values for the predictors.
#'
#' @examples
#' # Assuming a dataset named 'my_data' with appropriate columns
#' result <- model_explorer(data = my_data, y = "target_column",
#'                          x1 = "predictor1", x2 = "predictor2", x3 = "predictor3")
#' print(result)
#'
#'@export
#'
model_explorer <- function(data, y, x1, x2, x3 = NULL, x4 = NULL, x5 = NULL,
                           p_value_threshold = 0.05) {

  # Check for valid column names
  all_vars <- c(y, x1, x2, x3, x4, x5)
  if (!all(all_vars %in% names(data))) {
    stop("One or more variables not found in the dataset.")
  }

  # Filter predictor names that are actually provided
  predictor_names <- all_vars[!is.null(all_vars) & all_vars != y]

  # Create output data frame
  output_df <- data.frame(model = character(),
                          predictors = character(),
                          p_values = numeric())

  # Iterate through combinations and fit models
  for (i in 1:length(predictor_names)) {
    combos <- combn(predictor_names, i, simplify = FALSE)

    for (combo in combos) {
      formula_str <- paste0("y ~ ", paste(combo, collapse = " + "))
      formula_str <- paste(formula_str, " + ", paste0(combo, ":", combo, collapse = " + "))

      model <- lm(as.formula(formula_str), data = data)

      # Extract significant predictors and p-values
      summary_data <- summary(model)$coefficients[rowSums(summary(model)$coefficients[, 4] < p_value_threshold) > 0,]

      # Store results
      if (nrow(summary_data) > 0) {
        output_df <- rbind(output_df, data.frame(model = as.character(formula(model)),
                                                 predictors = list(rownames(summary_data)), # Nested list
                                                 p_values = list(summary_data[, "Pr(>|t|)"])))
      }
    }
  }

  return(output_df)
}
