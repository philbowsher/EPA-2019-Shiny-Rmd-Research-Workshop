EPA Water Quality Analysis
================

# Data Cleaning

This section outlines the process needed for cleaning data taken from
EPA.gov.

There are two datasets:

  - [Water
    Chemistry](https://www.epa.gov/sites/production/files/2014-10/nla2007_chemical_conditionestimates_20091123.csv)
  - [Sample Site
    Information](https://www.epa.gov/sites/production/files/2014-10/nla2007_chemical_conditionestimates_20091123.csv)

The first dataset contains data pertaining to water quality samples at a
given site. The second data set contains information relating to that
site such as latitude and longitude data. We will need to combine these
datasets.

In order to join any two datasets there must be a common field(s). This
case it is the `site_id`.

The below code chunk:

1.  Load the `tidyverse`
2.  Creates variables that store the URL of the csv files
3.  Read the datasets and standardizes the column names using the
    `clean_names()` function from janitor.

<!-- end list -->

``` r
library(tidyverse)

# identify water quality csv
water_url <- "https://www.epa.gov/sites/production/files/2014-10/nla2007_chemical_conditionestimates_20091123.csv"

# site info csv (w lat lon data)
site_url <- "https://www.epa.gov/sites/production/files/2014-01/nla2007_sampledlakeinformation_20091113.csv"

# read sites
sites <- read_csv(site_url) %>% 
  janitor::clean_names()

# read water
water_q <- read_csv(water_url) %>% 
  janitor::clean_names()
```

Now that we have these datasets we will need to join them together.In
this case we will join three tables together:

  - Water Quality dataset
  - Site location data
  - State abbreviation and region data

We first take only a few columns of interest from the `sites` dataset.
This is then piped ( %\>% ) into an `inner_join()` (all columns from x
and y where there is a match between x and y). The resultant table is
then passed forward into a `left_join()` (all columns from x and y where
returning all rows from x). In this join the y table is explicitly
created from the built in R objects `state.abb` and `state.region`.
Then, a `select()` statement is used to change some column names, select
only the columns of interest. Finally, the tibble is written to the
`data` directory (run `mkdir("data")`) if the directory does not exist.

``` r
# join together
# join together
clean <- select(sites, lon_dd, lat_dd, lakename, site_id, state_name, st) %>% 
  inner_join(water_q, by = "site_id") %>% 
  # join a table that has region info
  left_join(
    tibble(st = state.abb,
           region = state.region), by = c("st.y" = "st")
  ) %>% 
  # select only data of interest
  select(contains("_cond"), ptl, ntl, chla, st = st.x, region,
         lon_dd = lon_dd.x, lat_dd = lat_dd.x, lakename)


#write_csv(clean, "data/water_quality.csv") 
```

# Exploratory analysis

``` r
water <- read_csv("data/water_quality.csv")
```

    ## Parsed with column specification:
    ## cols(
    ##   ptl_cond = col_character(),
    ##   ntl_cond = col_character(),
    ##   chla_cond = col_character(),
    ##   turb_cond = col_character(),
    ##   anc_cond = col_character(),
    ##   salinity_cond = col_character(),
    ##   ptl = col_double(),
    ##   ntl = col_double(),
    ##   chla = col_double(),
    ##   st = col_character(),
    ##   region = col_character(),
    ##   lon_dd = col_double(),
    ##   lat_dd = col_double(),
    ##   lakename = col_character()
    ## )

``` r
glimpse(water)
```

    ## Observations: 1,442
    ## Variables: 14
    ## $ ptl_cond      <chr> "1:LEAST DISTURBED", "2:INTERMEDIATE DISTURBANCE",…
    ## $ ntl_cond      <chr> "1:LEAST DISTURBED", "2:INTERMEDIATE DISTURBANCE",…
    ## $ chla_cond     <chr> "1:LEAST DISTURBED", "1:LEAST DISTURBED", "1:LEAST…
    ## $ turb_cond     <chr> "1:LEAST DISTURBED", "1:LEAST DISTURBED", "1:LEAST…
    ## $ anc_cond      <chr> "1:LEAST DISTURBED", "1:LEAST DISTURBED", "1:LEAST…
    ## $ salinity_cond <chr> "1:LEAST DISTURBED", "1:LEAST DISTURBED", "1:LEAST…
    ## $ ptl           <dbl> 6, 36, 22, 36, 22, 43, 50, 43, 50, 18, 46, 18, 46,…
    ## $ ntl           <dbl> 151, 695, 469, 695, 469, 738, 843, 738, 843, 344, …
    ## $ chla          <dbl> 0.24, 3.84, 20.88, 3.84, 20.88, 16.96, 12.86, 16.9…
    ## $ st            <chr> "MT", "SC", "SC", "SC", "SC", "TX", "TX", "TX", "T…
    ## $ region        <chr> "West", "South", "South", "South", "South", "South…
    ## $ lon_dd        <dbl> -114.02184, -79.98379, -79.98379, -79.98379, -79.9…
    ## $ lat_dd        <dbl> 48.97903, 33.03606, 33.03606, 33.03606, 33.03606, …
    ## $ lakename      <chr> "Lake Wurdeman", "Crane Pond", "Crane Pond", "Cran…

Use ggplot2 to explore the relationship between numeric variables.

``` r
water %>% 
  ggplot(aes(ptl, ntl)) +
  geom_point(alpha = .25) +
  theme_minimal()
```

![](README_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

Notice the fanning nature of the chart,this alludes to a log normal
distribution. Apply log transformations on both axes via
`scale_x/y_log10()`.

``` r
water %>% 
  ggplot(aes(ptl, ntl)) +
  geom_point(alpha = .25) +
  theme_minimal() + 
  scale_x_log10() +
  scale_y_log10()
```

![](README_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

Wonderful\! Now there is a clear linear trend. Try applying a linear
regression to the data using `geom_smooth()`

``` r
water %>% 
  ggplot(aes(ptl, ntl)) +
  geom_point(alpha = .25) +
  theme_minimal() + 
  scale_x_log10() +
  scale_y_log10() +
  geom_smooth(method = "lm")
```

![](README_files/figure-gfm/unnamed-chunk-7-1.png)<!-- -->

This is great\! What are the values of our coefficient though? Fit a
model.

``` r
mod <- lm(log10(ntl) ~ log10(ptl), data = water)

summary(mod)
```

    ## 
    ## Call:
    ## lm(formula = log10(ntl) ~ log10(ptl), data = water)
    ## 
    ## Residuals:
    ##      Min       1Q   Median       3Q      Max 
    ## -1.28645 -0.16097 -0.01698  0.15165  1.07904 
    ## 
    ## Coefficients:
    ##             Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)  1.98542    0.01664  119.34   <2e-16 ***
    ## log10(ptl)   0.54567    0.01014   53.82   <2e-16 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 0.2707 on 1440 degrees of freedom
    ## Multiple R-squared:  0.668,  Adjusted R-squared:  0.6677 
    ## F-statistic:  2897 on 1 and 1440 DF,  p-value: < 2.2e-16

How does this change for a single region? We can filter the
data.

``` r
mod_west <- lm(log10(ntl) ~ log10(ptl), data = filter(water, region == "West"))
summary(mod_west)
```

    ## 
    ## Call:
    ## lm(formula = log10(ntl) ~ log10(ptl), data = filter(water, region == 
    ##     "West"))
    ## 
    ## Residuals:
    ##      Min       1Q   Median       3Q      Max 
    ## -1.18505 -0.15729 -0.00431  0.14501  1.18044 
    ## 
    ## Coefficients:
    ##             Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)  1.88402    0.02912   64.71   <2e-16 ***
    ## log10(ptl)   0.51157    0.01854   27.60   <2e-16 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 0.2827 on 375 degrees of freedom
    ## Multiple R-squared:  0.6701, Adjusted R-squared:  0.6692 
    ## F-statistic: 761.7 on 1 and 375 DF,  p-value: < 2.2e-16

There is some variation in this. What about all other regions? We can
use `purrr` to create multiple models.

``` r
region_mods <- water %>% 
  nest(-region) %>% 
  mutate(mod = map(.x = data, .f = ~lm(log10(.x$ntl) ~ log10(.x$ptl))),
         # create a nested tibble for model coefs
         results = map(mod, broom::tidy),
         # create nested tibble for model metrics
         summary = map(mod, broom::glance))
```

We can unnest different tibbles. For the coefficients unnest the
`results`.

``` r
unnest(region_mods, results)
```

    ## # A tibble: 8 x 6
    ##   region        term          estimate std.error statistic   p.value
    ##   <chr>         <chr>            <dbl>     <dbl>     <dbl>     <dbl>
    ## 1 West          (Intercept)      1.88     0.0291      64.7 1.47e-205
    ## 2 West          log10(.x$ptl)    0.512    0.0185      27.6 2.52e- 92
    ## 3 South         (Intercept)      1.99     0.0336      59.3 3.22e-186
    ## 4 South         log10(.x$ptl)    0.509    0.0203      25.1 1.16e- 80
    ## 5 Northeast     (Intercept)      2.10     0.0324      65.0 5.09e-122
    ## 6 Northeast     log10(.x$ptl)    0.417    0.0294      14.2 1.21e- 30
    ## 7 North Central (Intercept)      2.15     0.0280      76.7 2.15e-290
    ## 8 North Central log10(.x$ptl)    0.533    0.0154      34.5 4.18e-138

## Mapping data

To map data we can take advantage of `leaflet` and `sf`. We will create
a simple feature object which has a column containing geometry
information. We use `st_as_sf()` to convert to a spatial object. Use the
argument `coords` to tell which columns correspond to latitude and
logitude.

``` r
library(sf)
```

    ## Linking to GEOS 3.6.1, GDAL 2.1.3, PROJ 4.9.3

``` r
water_sf <- water %>% 
  st_as_sf(coords = c("lon_dd", "lat_dd"))

class(water_sf)
```

    ## [1] "sf"         "tbl_df"     "tbl"        "data.frame"

You can see now that this is still a data frame but is also of class
`sf`.

We can use this sf object to plot some markers with leaflet.

``` r
library(leaflet)

leaflet(water_sf) %>% 
        addTiles() %>% 
        addMarkers()
```

This creates markers for each measurement, but it would be nice to have
a popup message associated with each one. We can create a message with
`mutate()` and `glue()`. Note that the `<br>` tag is an html tag that
creates a new line.

``` r
water_sf %>% 
  mutate(msg = glue::glue({
    "Name: {lakename}<br>
    Chlorphylla: {chla}<br>
    Nitrogen: {ntl}<br>
    Phosphorus: {ptl}<br>"})) %>% 
  leaflet() %>% 
  addTiles() %>% 
  addMarkers(popup = ~msg)
```
