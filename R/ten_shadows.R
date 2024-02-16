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
        if (all(summary(model)$coefficients[interactions, 4] < p_value_threshold)) { # Check interaction p-values
          significant_shadows[[paste0("shadow_", i)]] <- list(dataset = shadow_data,
                                                              original_shadow = original_shadow,
                                                              model_summary = summary(model),
                                                              coefficients = coef(model)[interactions])
        }
      } else {
        warning("Cannot check interaction significance when no interactions are specified.")
      }
    } else {
      if (all(summary(model)$coefficients[predictors, 4] < p_value_threshold)) { # Check all predictors
        significant_shadows[[paste0("shadow_", i)]] <- list(dataset = shadow_data,
                                                            original_shadow = original_shadow,
                                                            model_summary = summary(model),
                                                            coefficients = coef(model)[predictors])
      }
    }
  }

  # Calculation and Output
  num_significant <- length(significant_shadows)
  percent_significant <- (num_significant / num_iterations) * 100

  # Average Coefficients Calculation (Simplified)
  if (num_significant > 0) {
    if (check_interaction) {
      # We trust the coefficient logic already filters coefficients from significant interactions
      if (!is.null(interactions)) {
        all_coefficients <- do.call(rbind, lapply(significant_shadows, function(x) x$coefficients))
        average_coefficients <- colMeans(all_coefficients)
        lowest_coefficients <- apply(all_coefficients, 2, min)  # Column-wise minimums
        highest_coefficients <- apply(all_coefficients, 2, max) # Column-wise maximums
        names(average_coefficients) <- interactions
        names(lowest_coefficients) <- interactions
        names(highest_coefficients) <- interactions
      } else {
        average_coefficients <- NULL
        lowest_coefficients <- NULL
        highest_coefficients <- NULL
        message("Error: We should in theory never reach this stage. Please contact the author.")
      }
    } else {
      # We trust the coefficient logic already filters coefficients of significant predictors
      all_coefficients <- do.call(rbind, lapply(significant_shadows, function(x) x$coefficients))
      average_coefficients <- colMeans(all_coefficients)
      lowest_coefficients <- apply(all_coefficients, 2, min)  # Column-wise minimums
      highest_coefficients <- apply(all_coefficients, 2, max) # Column-wise maximums
      names(average_coefficients) <- predictors
      names(lowest_coefficients) <- predictors
      names(highest_coefficients) <- predictors
    }
  }


  if (length(significant_shadows) == 0) {
    message("Error: The indicated predictor(s) (or interactions) were not significant after ", num_iterations, " iterations.")
  } else {
    message("Out of ", num_iterations, " iterations, ", percent_significant, "% resulted in significant shadow datasets.")

    # Simplified Coefficient Summary Messages
    if (!is.null(average_coefficients)) {
      header_row <- c("Variable", "Average Coefficient", "Lowest Coefficient", "Highest Coefficient")
      output_data <- data.frame(Variable = names(average_coefficients),
                                Average = format(round(average_coefficients, 3), nsmall = 3),
                                Lowest = format(round(lowest_coefficients, 3), nsmall = 3),
                                Highest = format(round(highest_coefficients, 3), nsmall = 3))

      # Optional: Print header nicely
      cat(sprintf("%-20s %-20s %-20s %-20s\n", header_row[1], header_row[2], header_row[3], header_row[4]))

      # Print rows
      for (i in 1:nrow(output_data)) {
        cat(sprintf("%-20s %-20s %-20s %-20s\n", output_data[i, 1], output_data[i, 2], output_data[i, 3], output_data[i, 4])) 
      }
    }

    return(significant_shadows)
  }
}


