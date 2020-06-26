
<!-- README.md is generated from README.Rmd. Please edit that file -->

# CPTraceR

<!-- badges: start -->

<!-- badges: end -->

The goal of CPTraceR is to add unique track ids to CellProfiler tracking
output.

## Installation

You can install the development version of CPTraceR with:

``` r
remotes::install_github("burgerga/CPTraceR")
```

## Example

Assuming `data` contains some data from a CellProfiler tsv:

The original data:

``` r
library(tidyverse)
data_select <- data %>%
  select(groupNumber, 
         groupInd, 
         par_obj_num = Nuclei_TrackObjects_ParentObjectNumber_30, 
         obj_num     = Nuclei_Number_Object_Number)
# example output from the first group
data_select %>% 
  filter(groupNumber == 1) %>%
  arrange(obj_num, groupInd)
#> # A tibble: 10,304 x 4
#>    groupNumber groupInd par_obj_num obj_num
#>          <dbl>    <dbl>       <dbl>   <dbl>
#>  1           1        1           0       1
#>  2           1        2           1       1
#>  3           1        3           1       1
#>  4           1        4           1       1
#>  5           1        5           0       1
#>  6           1        6           2       1
#>  7           1        7           0       1
#>  8           1        8           3       1
#>  9           1        9           1       1
#> 10           1       10           1       1
#> # … with 10,294 more rows
```

Let’s fix the output:

``` r
library(CPTraceR)
library(progressr) #enable progress bars
with_progress({
  fixed <- createLUTGroup(data_select %>% filter(groupNumber == 1) %>% select(-groupNumber)) 
})
fixed %>% 
  arrange(obj_num, groupInd)
#> # A tibble: 10,304 x 5
#>    groupInd obj_num   cid   uid alt_obj_num
#>       <dbl>   <dbl> <dbl> <dbl> <chr>      
#>  1        1       1     1     1 1          
#>  2        2       1     1     1 1          
#>  3        3       1     1     1 1          
#>  4        4       1     1     1 1          
#>  5        5       1   271   305 271        
#>  6        6       1     1     1 1          
#>  7        7       1   315   361 315        
#>  8        8       1   252   286 252        
#>  9        9       1   252   286 252        
#> 10       10       1   252   286 252        
#> # … with 10,294 more rows
```

Three new columns are added:

  - `cid`: id of the original cell (daughter cells share `cid` with
    parent)
  - `uid`: unique id (daughter cells don’t share `uid` with parent)
  - `alt_obj_num`: character id of cells that show lineage with suffixes

<!-- end list -->

``` r
fixed %>% 
  filter(groupInd == 2) %>%
  arrange(obj_num, groupInd)
#> # A tibble: 200 x 5
#>    groupInd obj_num   cid   uid alt_obj_num
#>       <dbl>   <dbl> <dbl> <dbl> <chr>      
#>  1        2       1     1     1 1          
#>  2        2       2     3   226 3.1        
#>  3        2       3     3   227 3.2        
#>  4        2       4     5     5 5          
#>  5        2       5     6     6 6          
#>  6        2       6    14   228 14.1       
#>  7        2       7     9     9 9          
#>  8        2       8    10    10 10         
#>  9        2       9    11    11 11         
#> 10        2      10    13    13 13         
#> # … with 190 more rows
```

Now run everything sequentially:

``` r
library(tictoc)
tic()
with_progress({
  createLUT(data_select) 
})
#> # A tibble: 370,598 x 4
#>    groupNumber groupInd par_obj_num obj_num
#>          <dbl>    <dbl>       <dbl>   <dbl>
#>  1           1        1           0       1
#>  2           1        1           0       2
#>  3           1        1           0       3
#>  4           1        1           0       4
#>  5           1        1           0       5
#>  6           1        1           0       6
#>  7           1        1           0       7
#>  8           1        1           0       8
#>  9           1        1           0       9
#> 10           1        1           0      10
#> # … with 370,588 more rows
toc()
#> 89.32 sec elapsed
```

Now run everything in parallel:

``` r
library(tictoc)
library(future)
plan(multisession)
tic()
with_progress({
  createLUT(data_select) 
})
#> # A tibble: 370,598 x 4
#>    groupNumber groupInd par_obj_num obj_num
#>          <dbl>    <dbl>       <dbl>   <dbl>
#>  1           1        1           0       1
#>  2           1        1           0       2
#>  3           1        1           0       3
#>  4           1        1           0       4
#>  5           1        1           0       5
#>  6           1        1           0       6
#>  7           1        1           0       7
#>  8           1        1           0       8
#>  9           1        1           0       9
#> 10           1        1           0      10
#> # … with 370,588 more rows
toc()
#> 34.139 sec elapsed
```
