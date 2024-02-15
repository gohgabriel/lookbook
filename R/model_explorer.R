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
  
  # Create an empty list to store output 
  output_list <- list() 
  
  # Build Formula Strings (Modified)
predictor_names <- var_names[!var_names %in% y_var] 

# 2. Two-way interactions 
interactions <- combn(predictor_names, 2, FUN = function(x) paste(x, collapse = ":"))

# 3. Create formulae using combn
all_combinations <- combn(c(predictor_names, interactions), m = 1:length(c(predictor_names, interactions)), simplify = FALSE)

formula_list <- lapply(all_combinations, function(combo) {
     paste0(y_var, " ~ ", paste(combo, collapse = " + "))
})

# 4. Filter for valid hierarchical models
formula_list <- formula_list[sapply(formula_list, function(f) {
  terms <- all.vars(f)
  interactions <- terms[grepl(":", terms)]
  if (length(interactions) == 0) return(TRUE) # No interactions 
  all(sapply(interactions, function(int_term) {
    all(strsplit(int_term, ":")[[1]] %in% terms) 
  }))
})]

      for (combo in combos) { 
  formula_str <- as.formula(formula_list[[length(formula_list)]]) # Assign from formula_list

  model <- lm(formula_str, data = data)  
  print(summary(model))
      
      # Extract significant predictors and p-values (Example threshold at p < 0.05)
      if (is.null(summary(model)$coefficients) || 
          ncol(summary(model)$coefficients) >= 4 ||
          nrow(summary(model)$coefficients) == 1) { 
        summary_data <- summary(model)$coefficients[summary(model)$coefficients[, 4] < p_value_threshold, ] 

      } else {
        summary_data <- NULL 
      }
      
      # Store results (with conditional check)
      if (!is.null(summary_data) && nrow(summary_data) > 0) { 
        output_list[[length(output_list) + 1]] <- list(model = as.character(formula(model)),
                                                       predictors = as.character(rownames(summary_data)),
                                                       p_values = summary_data[, "Pr(>|t|)"])
      }
      } 
    }
  

  # Check if any models were significant
  if (length(output_list) == 0) {
    message("No significant predictors found") 
  } else {
    output_df <- do.call(rbind, output_list) # Convert  list to  dataframe 
  }
  
  return(output_df)
}
