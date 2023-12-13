library(tibble)
library(dplyr)

test_that("split tracks get new uid and suffix", {
  data <- tribble(
    ~groupInd, ~par_obj_num, ~obj_num,
    1, 0, 1,
    2, 1, 1,
    2, 1, 2
  )
  lut <- createLUTGroup(data,
                       frame_var = groupInd,
                       obj_var = obj_num,
                       par_obj_var = par_obj_num)
  expect_equal(lut$uid, c(1,2,3))
  expect_equal(lut$alt_uid, c('1', '1.1', '1.2'))
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

test_that("new tracks get new uid/cid, even if highest uid/cid so far is not in the previous frame", {
  # In case new cells appear
  data1 <- tribble(
    ~groupInd, ~par_obj_num, ~obj_num,
    1, 0, 1, # cell 1
    1, 0, 2, # cell 2
    2, 1, 1, # cell 1 in frame 2, cell 2 disappears
    3, 1, 1, # cell 1 in frame 3
    3, 0, 2, # cell 3 appears
  )
  lut1 <- createLUTGroup(data1,
                        frame_var = groupInd,
                        obj_var = obj_num,
                        par_obj_var = par_obj_num)
  expect_equal(lut1$uid, c(1,2,1,1,3))
  expect_equal(lut1$cid, c(1,2,1,1,3))

  # In case a cell splits
  data2 <- tribble(
    ~groupInd, ~par_obj_num, ~obj_num,
    1, 0, 1, # cell 1
    1, 0, 2, # cell 2
    2, 1, 1, # cell 1 in frame 2, cell 2 disappears
    3, 1, 1, # cell 1 has now split in frame 3, this is the first daughter cell of 1
    3, 1, 2, # cell 3 appears as the second daughter cell of 1
  )
  lut2 <- createLUTGroup(data2,
                         frame_var = groupInd,
                         obj_var = obj_num,
                         par_obj_var = par_obj_num)
  expect_equal(lut2$uid, c(1,2,1,3,4))

  data3 <- tribble(
    ~groupInd, ~par_obj_num, ~obj_num,
    1, 0, 1, # cell 1
    1, 0, 2, # cell 2
    2, 1, 1, # cell 1 in frame 2, cell 2 disappears
    3, 1, 1, # cell 1 has now split in frame 3, this is the first daughter cell of 1
    3, 1, 2, # cell 3 appears as the second daughter cell of 1
    4, 0, 1, # cell 4 appears
  )
  lut3 <- createLUTGroup(data3,
                         frame_var = groupInd,
                         obj_var = obj_num,
                         par_obj_var = par_obj_num)
  expect_equal(lut3$cid, c(1,2,1,1,1,3))
  expect_equal(lut3$uid, c(1,2,1,3,4,5))
})
