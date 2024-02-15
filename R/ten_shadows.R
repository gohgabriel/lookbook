#' Sensitivity Analysis with Randomized Subsets
#'
#' The `ten_shadows` function investigates the robustness of statistical relationships by
#' repeatedly fitting a linear model to randomly reduced subsets of the original dataset.
#' This method helps identify cases where findings may be sensitive to the inclusion or
#' exclusion of specific observations.
#'
#' @param dataset A data frame containing the variables for the sensitivity analysis.
#' @param predictors A character vector specifying the predictor variables of interest.
#' @param outcome A character string specifying the outcome (dependent) variable.
#' @param controls A character vector (optional) specifying control variables to include in the model.
#' @param interactions A character vector (optional) of variable interactions. Interaction
#'   terms should be formatted as `"var1:var2"`. Ensure main effects for interactions are
#'   included within `predictors` or `controls`.
#' @param num_obs_remove An integer (optional) specifying the number of observations to remove
#'   in each iteration. If not provided, 10% of observations will be removed.
#' @param num_iterations An integer specifying the number of model iterations to perform.
#'   Defaults to 10.
#' @param p_value_threshold A numeric value indicating the significance threshold for
#'   determining a "significant" shadow dataset. Defaults to 0.05.
#' @param check_interaction A logical value. If `TRUE`, checks for significant interactions
#'    (if interaction terms are provided). Defaults to `FALSE`.
#'
#' @return A list containing all shadow datasets where either predictors or their specified
#'   interactions (if applicable) were found to be statistically significant. Each list
#'   element is named "shadow_1", "shadow_2", etc. and contains:
#'   * **dataset:** The subset of data used for that iteration.
#'   * **model_summary:** The output from `summary(lm())`.
#'
#' @details Each iteration involves randomly removing observations, refitting the
#'   linear model, and assessing significance. If no shadow datasets reach significance,
#'   an error is returned indicating potential robustness of the predictors.
#'
#' @examples
#' \dontrun{
#' # Example usage with the 'mtcars' dataset
#' results <- ten_shadows(dataset = mtcars,
#'                        predictors = c("mpg", "hp"),
#'                        outcome = "wt",
#'                        controls = "cyl")
#' }
#'
#' @export

ten_shadows <- function(dataset,
                        predictors,  # Accepts a vector
                        outcome,
                        controls = NULL, # Accepts a vector
                        interactions = NULL,
                        num_obs_remove = NULL,
                        num_iterations = 10,
                        p_value_threshold = 0.05,
                        check_interaction = FALSE) {

  significant_shadows <- list()

  original_shadow <- dataset %>%  # You might need 'library(dplyr)' for this
    mutate(obs_id = row_number())

  for (i in 1:num_iterations) {

    # Calculate 10% to remove, ensuring at least 1 observation
    if (is.null(num_obs_remove)) {
      num_obs_remove <- max(1, round(0.10 * nrow(original_shadow)))
    }

    shadow_data <- original_shadow[sample(nrow(original_shadow), nrow(original_shadow) - num_obs_remove), ]

    # Build the base model formula
    model_formula <- as.formula(paste(outcome, "~", paste(predictors, collapse = " + ")))

    # Process interactions (if any)
    if (!is.null(interactions)) {
      interaction_terms <- lapply(interactions, function(term) {
        # Split interaction term (e.g., "var1:var2")
        term_parts <- unlist(strsplit(term, ":"))

        # Check if main effects are present
        if (!(all(term_parts %in% c(predictors, controls)))) {
          stop("Interactions must include their subordinate main effects in the model.")
        }
        paste(term_parts, collapse = ":")
      })
      model_formula <- update(model_formula, paste0(". ~ . + ", paste(interaction_terms, collapse= " + ")))
    }

    # Add controls (if any)
    if (!is.null(controls)) {
      control_part <- paste(controls, collapse = " + ")
      model_formula <- update(model_formula, paste0(". ~ . + ", control_part))
    }

    model <- lm(model_formula, data = shadow_data)


    # Significance checking logic
    if (check_interaction) {
      if (!is.null(interactions)) {
        if (any(summary(model)$coefficients[interactions, 4] < p_value_threshold)) { # Check interaction p-values
          significant_shadows[[paste0("shadow_", i)]] <- shadow_data
        }
      } else {
        warning("Cannot check interaction significance when no interactions are specified.")
      }
    } else {
      if (all(summary(model)$coefficients[predictors, 4] < p_value_threshold)) { # Check all predictors
        significant_shadows[[paste0("shadow_", i)]] <- list(dataset = shadow_data,
                                                            original_shadow = original_shadow,
                                                            model_summary = summary(model))
      }
    }
  }

  # Calculation and Output
  num_significant <- length(significant_shadows)
  percent_significant <- (num_significant / num_iterations) * 100

  if (length(significant_shadows) == 0) {
    message("Error: The indicated predictor(s) (or interactions) were not significant after ", num_iterations, " iterations.")
  } else {
    message("Out of ", num_iterations, " iterations, ", percent_significant, "% resulted in significant shadow datasets.")
    return(significant_shadows)
  }
}


