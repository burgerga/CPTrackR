context("Fixing track ids")
library(tibble)
library(dplyr)

test_that("split tracks get suffix", {
  data <- tribble(
    ~groupInd, ~par_obj_num, ~obj_num,
    1, 0, 1,
    2, 1, 1,
    2, 1, 2
  )
  expect_equal(createLUTGroup(data,
                              frame_var = groupInd,
                              obj_var = obj_num,
                              par_obj_var = par_obj_num)$alt_uid,
               c('1', '1.1', '1.2'))
})

# Added because continued tracks with multiple parents could
# get same uid as newly added tracks
test_that("tracks get unique uid", {
  data <- tribble(
    ~groupInd, ~par_obj_num, ~obj_num,
    1, 0, 1,
    2, 1, 1,
    2, 1, 2,
    2, 0, 3
  )
  expect_true(
    n_distinct(createLUTGroup(data,
                              frame_var = groupInd,
                              obj_var = obj_num,
                              par_obj_var = par_obj_num)$uid) == 4)
})
