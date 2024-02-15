README.md

# Lookbook

Lookbook is a R library with various R functions designed to explore patterns in your datasets.

# Installation

You can install the "lookbook" package directly from GitHub using the devtools package in R:

```
# If you don't have 'devtools' installed yet:
install.packages("devtools")

# Install the 'lookbook' package
devtools::install_github("gohgabriel/lookbook")
```

## Model Explorer

Model explorer facilitates a structured approach to investigating the relationship between a dependent variable and multiple independent variables within a dataset. It systematically generates and evaluates various linear models, aiding in the discovery of significant predictors and their interactions.

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
* p_value_threshold (optional): The p-value threshold for statistical significance (default = 0.05).

### Output

The function returns a data frame with the following columns:

```
    model: The model formula.
    significant_predictors: A list of statistically significant predictors.
    p_values: A list of corresponding p-values.
```

### Example

```
library(datasets)  # Use the built-in 'mtcars' dataset

result <- model_explorer(data = mtcars, y_var = "mpg", 
                         x1_var = "cyl", x2_var = "disp", x3_var = "hp")
print(result)
```

## Sensitivity Analysis with Randomized Subsets (Shadow Sensitivity Analysis)

The ten_shadows function performs sensitivity analysis within a linear regression framework. It helps gauge the robustness of your model by repeatedly fitting it on random subsets of the data and checking if the original predictors (or interactions) remain statistically significant. The function is capable of incorporating two-way interaction terms, and also can be set to focus on the significance of the interaction term rather than on the indicated predictors.

A good rule of thumb is that for the default ten iterations, predictors (or interactions) should be significant across 100% of them. A paper detailing the methods of the function, relative to other sensitivity analyses, is forthcoming.

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

The ten_shadows function returns a list. Each element of the list (named "shadow_1", "shadow_2", etc.) corresponds to an iteration where the variables were significant and includes:

```
dataset: The subset of data used for that iteration.
model_summary: The output of summary(lm()) for the fitted model.
```

If no iterations yield significant findings, an error message is returned. This is a good indication about the relative robustness of the predictors/interactions.

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

