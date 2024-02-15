#' @title Analyze Sensitivity Analysis Output
#' @description Calculates observation inclusion/exclusion frequencies from the results of a sensitivity analysis from the `ten_shadows` function.
#' @param results Output list from a sensitivity analysis function.
#' @param top_n Optional. An integer controlling the number of top excluded/included observations to report. Defaults to 10% of the observations in the original dataset.
#' @return A list containing:
#' \itemize{
#'   \item excluded_frequencies: A list of exclusion frequency vectors for each shadow dataset.
#'   \item included_frequencies: A list of inclusion frequency vectors for each shadow dataset.
#'   \item total_excluded: Total exclusion frequencies across all datasets.
#'   \item total_included: Total inclusion frequencies across all datasets.
#'   \item top_excluded_obs: IDs of the top excluded observations.
#'   \item top_included_obs: IDs of the top included observations.
#'   \item top_excluded_df: Data frame containing rows for the top excluded observations.
#'   \item top_included_df: Data frame containing rows for the top included observations.
#' }
#' @importFrom dplyr %>%
#' @export
#'
#'

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

  # Sort to Find Most Frequent
  sorted_excluded <- sort(total_excluded, decreasing = TRUE)
  sorted_included <- sort(total_included, decreasing = TRUE)

  # Get IDs with Max Frequencies
  top_excluded_ids <- names(sorted_excluded)[1:top_n]
  top_included_ids <- names(sorted_included)[1:top_n]

  # Create Data Frames
  top_excluded_df <- original_shadow[original_shadow$obs_id %in% top_excluded_ids, ]
  top_included_df <- original_shadow[original_shadow$obs_id %in% top_included_ids, ]

  return(list(excluded_frequencies = excluded_freqs,
              included_frequencies = included_freqs,
              total_excluded = total_excluded,
              total_included = total_included,
              top_excluded_obs = top_excluded_ids,
              top_included_obs = top_included_ids,
              top_excluded_df = top_excluded_df,
              top_included_df = top_included_df))
}
