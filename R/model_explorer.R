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

    # Extract significant predictors and p-values (Example threshold at p < 0.05)
    if (is.null(summary(model)$coefficients) ||
        ncol(summary(model)$coefficients) >= 4 ||
        nrow(summary(model)$coefficients) == 1) {
      summary_data <- summary(model)$coefficients[summary(model)$coefficients[, 4] < p_value_threshold, ]

    } else {
      summary_data <- NULL
    }

  # Store results (with error handling)
  if (!is.null(summary_data) && nrow(summary_data) > 0) {
    output_list[[length(output_list) + 1]] <- list(model = formula_str,
                                                   significant_predictors = as.character(rownames(summary_data)),
                                                   p_values = summary_data[, "Pr(>|t|)"]) 

  } else {  # Add this section to handle possible NULL
    print(paste0("Model with formula '", formula_str, "' did not produce significant predictors."))
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
