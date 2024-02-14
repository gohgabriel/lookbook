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
#' @export
#'
model_explorer <- function(data, 
                           y_var, x1_var, x2_var, x3_var = NULL, x4_var = NULL, x5_var = NULL,
                           p_value_threshold = 0.05) {

  # Ensure valid column names 
  all_vars <- c(y_var, x1_var, x2_var, x3_var, x4_var, x5_var)
  if (!all(all_vars %in% names(data))) {
    stop("One or more variables not found in the dataset.")
  }

  # Filter non-NULL variable names
   var_names <- c(y_var, x1_var, x2_var, x3_var, x4_var, x5_var)[!is.null(c(y_var, x1_var, x2_var, x3_var, x4_var, x5_var))]
  
   # Substitute user-specified variable names 
   data <- rename(data, setNames(var_names, var_names))

  # Filter predictor names (redundant since renaming won't leave NULLs)
  predictor_names <- var_names[!is.null(var_names) & var_names != y_var]

  # Create output data frame
  output_df <- data.frame(model = character(),
                          predictors = character(),
                          p_values = numeric())

  # Build Formula Strings - NEW APPROACH
   for (i in 1:length(var_names)) {
      combos <- combn(var_names, i, simplify = FALSE)

      # Exclude combos with only the y_var 
      combos <- combos[lapply(combos, function(x) !all(x == y_var))]
     
      for (combo in combos) {
        formula_text <- paste0(y_var, " ~ ", paste(combo, collapse = " + "))
        formula_text <- paste(formula_text, " + ", paste0(combo, ":", combo, collapse = " + "))
        formula_str <- as.formula(formula_text) 

        model <- lm(formula_str, data = data)
        
# Extract significant predictors and p-values (Example threshold at p < 0.05)
if (ncol(summary(model)$coefficients) >= 4) {  # Check if p-values exist
  summary_data <- summary(model)$coefficients[rowSums(summary(model)$coefficients[, 4] < p_value_threshold) > 0,] 
} else {
  summary_data <- NULL  # Handle when no predictors are significant
}

# Store results
if (!is.null(summary_data)) { # Store only if predictors were significant 
  output_df <- rbind(output_df, data.frame(model = as.character(formula(model)),
                                             predictors = list(rownames(summary_data)),
                                             p_values = list(summary_data[, "Pr(>|t|)"])))
}
    }
  }

  return(output_df)
}
