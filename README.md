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

The model_explorer function facilitates exploring linear regression models to identify statistically significant predictors within a dataset, from two to five predictors. It will also automatically explore two-way interaction terms.

### Usage

```
result <- model_explorer(data = my_data, y = "target_column", 
                         x1 = "predictor1", x2 = "predictor2", x3 = "predictor3")
print(result) 
```

### Parameters

* data: A data frame containing the variables.
* y: The name of the target variable (as a string).
* x1, x2, ... (up to x5): The names of predictor variables (as strings).
* p_value_threshold (optional): The p-value threshold for statistical significance (default = 0.05).

### Output

The function returns a data frame with the following columns:

```
    model: The model formula.
    predictors: A list of statistically significant predictors.
    p_values: A list of corresponding p-values.
```

### Example

```
library(datasets)  # Use the built-in 'mtcars' dataset

result <- model_explorer(data = mtcars, y = "mpg", 
                         x1 = "cyl", x2 = "disp", x3 = "hp")
print(result)
```

