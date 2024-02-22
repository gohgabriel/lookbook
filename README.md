README.md

# Lookbook

Lookbook is a R package with various R functions designed to explore patterns in your datasets.

It currently has the following functions:
* model_explorer
* ten_shadows
* shadow_read
* s_weighted_bootstrap
* checkerboard_upscaler

# Installation

You can install the "lookbook" package directly from GitHub using the devtools package in R:

```
# If you don't have 'devtools' installed yet:
install.packages("devtools")

# Install the 'lookbook' package
devtools::install_github("gohgabriel/lookbook")
```

## Model Explorer

Model explorer facilitates a structured approach to investigating the relationship between a dependent variable and multiple independent variables within a dataset. It systematically generates and evaluates various linear models, aiding in the discovery of significant predictors and their interactions. The function will also automatically include and iterate through all possible two-way interactions between specified variables in the model building process.

The output is a matrix with models that have at least one significant predictor (excluding the intercept), together with the significant predictors, p-values, and model r-squared. It optionally has the function to sort the matrix by r-squared, facilitating the identification of combinations of predictors that explain the most variance in the data.

### Usage

```
# Assuming 'my_data' is your dataset, with variables  
# 'outcome', 'pred1', 'pred2', ... 
result <- model_explorer(data = my_data, y_var = "outcome", x1_var = "pred1", x2_var = "pred2") 

print(result)
```

### Parameters

* data: A data frame containing the variables.
* y_var: The name of the target variable (as a string).
* x1_var, x2_var, ... (up to x5_var): The names of predictor variables (as strings).
* sort: Whether or not to sort the output matrix based on r-squared (default = TRUE).
* p_value_threshold (optional): The p-value threshold for statistical significance (default = 0.05).

### Output

The function returns a matrix with the following columns:

```
    model: The model formula.
    significant_predictors: A list of statistically significant predictors.
    p_values: A list of corresponding p-values.
    r-squared: The r-squared of the fitted model.
```

### Example

```
library(datasets)  # Use the built-in 'mtcars' dataset

result <- model_explorer(data = mtcars, y_var = "mpg", 
                         x1_var = "cyl", x2_var = "disp", x3_var = "hp")
print(result)
```

## Sensitivity analysis with repeated random subsampling

Suppose that you've identified some relationships in your data using model explorer. Yet, given the large number of tests you are performing, there is a good chance that the relationships you have identified are spurrious. It would be particularly helpful to know the robustness of a particular finding with sensitivity analyses.

The ten_shadows function, based on repeated random subsampling techniques (or Monte Carlo cross-validation), performs sensitivity analysis for linear models including for moderation hypotheses. It helps gauge the robustness of your findings by repeatedly fitting it on random subsets of the data and checking if the original predictors (or interactions) remain statistically significant. The function is capable of incorporating two-way interaction terms, and also can be set to focus on the significance of the interaction terms rather than on the indicated predictors. As with all Monte Carlo techniques, some variation in the output is inevitable.

Additionally, ten_shadows provides MSE statistics, replicating the functionality of other repeated random subsampling or other cross-validation techniques. As the number of iterations approaches infinity, the ten_shadows function will tend towards findings using leave-p-out cross-validation subsampling techniques. However, as models become more complex and datasets become larger, the computational complexity of the function exponentially grows, which may lead to long processing times. A recommended starting point is to perform just 10 iterations, leaving the option to increase this to 1000 or 10000 depending on performance.

A good rule of thumb is that for the default 10 iterations, predictors (or interactions) should be significant across 100% of them. For larger numbers of iterations, a performance metric of at least 95% is ideal.

### Usage

```
library(lookbook)

results <- ten_shadows(dataset = my_data, 
                       predictors = c("var1", "var2"), 
                       outcome = "outcome_var",
                       controls = c("control1"), 
                       interactions = c("var1:var2"),
                       num_iterations = 10) 
```

### Parameters

* dataset: The data frame containing your variables.
* predictors: A character vector of predictor variable names.
* outcome: A character string specifying the outcome variable.
* controls: (Optional) A character vector of control variables.
* interactions: (Optional) A character vector of interaction terms (e.g., "var1:var2"). Make sure main effects are included in predictors or controls.
* num_obs_remove: (Optional) The number of observations to remove each iteration (default is 10% of the data).
* num_iterations: (Optional) The number of iterations (default is 10).
* p_value_threshold: (Optional) The p-value for determining significant variables (default is 0.05).
* check_interaction: (Optional) If TRUE, checks interaction significance over predictor significance (default FALSE).

### Output

The function prints the MSE summary statistics and the performance metric, indicating the percentage of iterations that result in significant findings for the indicated predictors/interactions. It also provides the range of regression coefficients across all resampling subsets, which may be a useful metric to gauge the relative robustness of a particular finding.

The ten_shadows function returns a list. Each element of the list (named "shadow_1", "shadow_2", etc.) corresponds to an iteration where the variables were significant and includes:

```
dataset: The subset of data used for that iteration.
original_shadow: The original dataset from which the subset is created from.
model_summary: The output of summary(lm()) for the fitted model.
```

If no iterations yield significant findings, an error message is returned. This is a good indication that the indicated relationships are not robust.

### Example

```
library(lookbook)

results <- ten_shadows(dataset = mtcars, 
                       predictors = c("mpg", "hp"), 
                       outcome = "wt",
                       controls = "cyl") 

# View the data used in the first shadow iteration
results[["shadow_1"]]$dataset

# View the model summary for the first shadow iteration
results[["shadow_1"]]$model_summary
```

## Shadow Read

The significance of the predictors/interactions may be contingent on the inclusion or exclusion of certain observations from a given data. When fitting predictors or interactions that are significant only for a low percentage of shadow subsets, it may be helpful to identify the most commonly included and excluded observations from the shadow subsets, revealing more clues regarding the sensitivity of the findings.

The shadow_read function analyses results from the ten_shadows function, and calculates the observation inclusion and exclusion frequencies across subsets. Based on these frequencies, the function also calculates an inclusion weight that can be passed to bootstrapping functions (e.g. boot), or the s_weighted_bootstrap function in the next section.

### Usage

```
results <- ten_shadows(dataset = mtcars, 
                       predictors = c("mpg", "hp"), 
                       outcome = "wt",
                       controls = "cyl") 

analysis_results <- shadow_read(results, top_n = NULL)
```

### Parameters

* results: (Required) A list containing the output from a sensitivity analysis function. This list should typically include individual shadow datasets (subsets) and the original dataset along with appropriate identifiers.
* top_n: (Optional)  Controls the number of top excluded and included observations reported. Defaults to 10% of the observations in the original dataset.

### Output

A list containing the following elements:

* original_dataset: The original un-subsetted dataset, with the added obs_id for consistency across functions.
* model_formula: The inherited model formula.
* excluded_frequencies: A list of exclusion frequency vectors for each shadow dataset.
* included_frequencies:  A list of inclusion frequency vectors for each shadow dataset.
* total_excluded: Total exclusion frequency vector across all datasets.
* total_included: Total inclusion frequency vector across all datasets.
* top_excluded_obs: IDs of the most frequently excluded observations, generated by the ten_shadows function.
* top_included_obs: IDs of  the most frequently included observations, generated by the ten_shadows function.
* top_excluded_df: A dataFrame where each row is one of the top excluded observations, retaining all its original variable data.
* top_included_df: A dataFrame where each row is one of the top included observations, retaining all its original variable data.
* inclusion_weights: Monte Carlo subset inclusion weights that can be passed to other functions in R.

### Example

```
library(lookbook)

# Using the mtcars dataset as an example.
results <- ten_shadows(dataset = mtcars,
                       predictors = c("wt","disp"),
                       outcome = "mpg",
                       num_iterations = 1000)

# Only 15.3% of shadowsets produce significant findings for wt and disp as predictors at the same time.

output <- shadow_read(results = results)

# The dataframes below suggest that the significant findings are contingent on the exclusion/inclusion of the observations below.
output$top_excluded_df
output$top_included_df

# The user may also examine the frequency table of excluded datasets.
output$total_excluded

# Also the inclusion weights.
output$inclusion_weights

# The dataset and inclusion weights can be passed to other functions, such as lavaan.
simplefit <- sem(model, data = output$original_dataset, sampling.weights = "obs_weight", estimator = "ML")
```

## Monte Carlo subset weighted Bootstrap

The read_shadow function provides inclusion weights (obs_weight), based on results from Monte Carlo cross-validation, in the dataset in its output. The s_weighted_bootstrap function is a function that can perform weighted bootstrapping based on these weights, as other packages like lavaan must use ML estimators when weights are specified.

### Usage

```
bootstrapped_coefs <- s_weighted_bootstrap(output, num_bootstraps = 1000)
```

### Parameters

* shadow_results: An output from the read_shadows function.

* num_bootstraps: The desired number of bootstrap iterations.

* refit_model: A logical flag (Default: TRUE). If TRUE, a new model is fit on each bootstrapped sample. If  FALSE,  original model coefficients are re-used.

* conf_level:  Decimal value (0 to 1)  specifying the  confidence level for the constructed  intervals (e.g., 0.95 for 95%). Default is 0.95.

### Output

Printed Output: The function  displays the following, making interpretation of  results immediate:

    Model formula.
    Descriptive bootstrapping statement specifying technique and confidence level.
    Table showing lower and upper bounds of calculated confidence intervals for each model coefficient.

## Checkerboard upscaling

Flexible data upscaling function for generating new observations, imputing missing values, and supporting various modeling and analysis scenarios.

### Features

* Diverse Imputation Methods:
    * Linear regression
    * Random forests (using the 'randomForest' package)
    * Bayesian regression (using the 'brms' package)
    * Easily extendable to incorporate additional imputation techniques

* Automatic Handling of Low-Variability Columns: Detects columns with few unique values and directly copies them during the upscaling process.

* Checkerboard Output: Optionally interweaves original and upscaled rows, creating datasets suitable for simulation-like studies.

* Customizable Threshold: Control which columns are considered low-variability using the uniq_threshold parameter.

### Dependencies

randomForest (for random forest), brms (for Bayesian regression)

### Usage

```
# Sample data
data <- data.frame(col1 = c(1, 2, NA, 4),
                   col2 = c("A", "A", "B", "B"),
                   col3 = c(10.5, 8.2, 3.4, NA))

# Upscale with linear regression imputation and checkerboard output
result1 <- checkerboard_upscale(data, imputation_method = "linear_regression")

# Upscale with Bayesian imputation (non-checkerboard output)
result2 <- checkerboard_upscale(data, imputation_method = "bayesian", checkerboard = FALSE)
```

### Parameters

    data: The input data frame.
    unsplit_cols: A vector of column names to be copied directly without imputation.
    imputation_method: The imputation method to use. Supported options: "linear_regression", "random_forest", "bayesian".
    checkerboard: Boolean flag to enable checkerboarded interweaving of rows. If FALSE, creates a completely generated version of the original dataset of the same size.
    uniq_threshold: Threshold for detecting low-variability columns.

