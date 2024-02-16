#' @export

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

  # Generate base set of predictors (Individual effects + Interactions)
  predictor_names <- var_names[!var_names %in% y_var]
  all_predictors <- predictor_names
  if (length(predictor_names) > 1) {
    interaction_preds <- combn(predictor_names, 2, FUN = function(x) paste(x, collapse = ":"))
    all_predictors <- c(all_predictors, interaction_preds)
  }

  # Generate all possible combinations of predictors (Modified)
  predictor_combinations <- lapply(1:length(all_predictors), function(num_terms) {
    all_combos <- combn(all_predictors, num_terms, simplify = FALSE)

    # Revised Filtering Logic
    filtered_combos <- all_combos[sapply(all_combos, function(combo) {
      if (any(grepl(":", combo))) { # Has interaction terms
        interaction_parts <- lapply(strsplit(combo[grepl(":", combo)], ":"), unique)
        all(sapply(interaction_parts, function(x) all(x %in% combo)))
      } else {
        TRUE # No interaction terms = valid
      }
    })]

    filtered_combos
  })

  # Flatten the list of combinations
  predictor_combinations <- unlist(predictor_combinations, recursive = FALSE)

  # Generate formulae from filtered combinations (This block now executes only if combinations exist)
  formula_list <- lapply(predictor_combinations, function(combo) {
    as.formula(paste0(y_var, " ~ ", paste(combo, collapse = " + ")))
  })


 # Loop through formulae
for (formula_str_index in 1:length(formula_list)) {
  formula_str <- as.formula(formula_list[[formula_str_index]])

  model <- lm(formula_str, data = data)

  # Check for typical model output
  if (is_typical_model_output(model)) {  # We'll define this function next

    # Extract significant predictors and p-values 
    if (is.null(summary(model)$coefficients) ||
        ncol(summary(model)$coefficients) >= 4 ||
        nrow(summary(model)$coefficients) == 1) {
      summary_data <- summary(model)$coefficients[summary(model)$coefficients[, 4] < p_value_threshold, ]
    } else {
      summary_data <- NULL
    } 

    # Store results (We no longer need error handling here)
    output_list[[length(output_list) + 1]] <- list(model = formula_str,
                                                   significant_predictors = as.character(rownames(summary_data)),
                                                   p_values = summary_data[, "Pr(>|t|)"]) 

  } else { 
    # Skip iteration (model output was atypical) 
  } 
}


  # Check if any models were significant
  if (length(output_list) == 0) {
    message("No significant predictors found")
  } else {
    output_df <- do.call(rbind, output_list) # Convert list to dataframe
  }

  return(output_df)

}

is_typical_model_output <- function(model) {
  # Here, you'll add checks based on what constitutes "typical" model output

  # Some potential checks (adjust to your needs):
  if (class(model) != "lm") {
    return(FALSE) # Not a standard 'lm' output
  }

  if (length(model$coefficients) == 0) {
    return(FALSE) # Model has no coefficients 
  }

   # New checks:
  summary_coefficients <- summary(model)$coefficients
  if (!"Pr(>|t|)" %in% colnames(summary_coefficients)) {
    return(FALSE) # Missing "Pr(>|t|)" column
  }

  if (length(rownames(summary_coefficients)) != length(model$coefficients)) {
    return(FALSE) # Predictors were dropped
  }

  return(TRUE) # Passes all checks
}
