#' @export

shadow_read <- function(results, top_n = NULL) {

  excluded_freqs <- list() # Store frequencies for each shadow
  included_freqs <- list()

  # Iterate through each shadow dataset
  for (i in seq_along(results)) {
    shadow_name <- names(results)[i]
    shadow_data <- results[[shadow_name]]$dataset
    shadow_ids <- shadow_data$obs_id

    obs_ids <- results[[shadow_name]]$original_shadow$obs_id # Get all unique obs_ids
    original_shadow <- results[[shadow_name]]$original_shadow
    model_formula <- results[[shadow_name]]$model_formula

    # Initialize vectors for this shadow
    excluded_frequencies <- rep(0, length(obs_ids))
    names(excluded_frequencies) <- obs_ids
    included_frequencies <- rep(0, length(obs_ids))
    names(included_frequencies) <- obs_ids

    # Update frequencies
    for (obs_id in obs_ids) {
      if (obs_id %in% shadow_ids) {
        included_frequencies[obs_id] <- included_frequencies[obs_id] + 1
      } else {
        excluded_frequencies[obs_id] <- excluded_frequencies[obs_id] + 1
      }
    }

    excluded_freqs[[shadow_name]] <- excluded_frequencies
    included_freqs[[shadow_name]] <- included_frequencies

    # Calculate Top 'N' (with default)
    num_obs <- nrow(results[[shadow_name]]$original_shadow) # Number of observations
    if (is.null(top_n)) {
      top_n <- round(0.10 * num_obs) # Default: 10% of observations
    }
  }

  # Summarize Frequencies
  total_excluded <- Reduce("+", excluded_freqs)
  total_included <- Reduce("+", included_freqs)

  # Calculate Inclusion Weights Across ALL Subsets
  mean_inclusion_freq <- mean(total_included)   # Mean across the original dataset
  inclusion_weights <- total_included / mean_inclusion_freq
  names(inclusion_weights) <- names(total_included)

  # Sort to Find Most Frequent
  sorted_excluded <- sort(total_excluded, decreasing = TRUE)
  sorted_included <- sort(total_included, decreasing = TRUE)

  # Get IDs with Max Frequencies
  top_excluded_ids <- names(sorted_excluded)[1:top_n]
  top_included_ids <- names(sorted_included)[1:top_n]

  # Create Data Frames
  top_excluded_df <- original_shadow[original_shadow$obs_id %in% top_excluded_ids, ]
  top_included_df <- original_shadow[original_shadow$obs_id %in% top_included_ids, ]

  return(list(original_dataset = cbind(original_shadow, obs_weight = inclusion_weights),
              model_formula = model_formula,
              excluded_frequencies = excluded_freqs,
              included_frequencies = included_freqs,
              total_excluded = total_excluded,
              total_included = total_included,
              top_excluded_obs = top_excluded_ids,
              top_included_obs = top_included_ids,
              top_excluded_df = top_excluded_df,
              top_included_df = top_included_df,
              inclusion_weights = inclusion_weights)
  )
}
