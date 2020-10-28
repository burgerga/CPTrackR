context("Fixing track ids")
library(tibble)

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
