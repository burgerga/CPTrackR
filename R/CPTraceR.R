#' CPTrackR:  Create unique track identifiers for CellProfiler tracking output
#'
#' By default CellProfiler does not export unique track ids, this package fixes that.
#'
#' @docType package
#' @name CPTrackR
#'
#' @importFrom magrittr %>%
#' @import dplyr
#' @importFrom tidyr nest unnest
#' @importFrom stringr str_glue
#' @importFrom purrr map
#' @importFrom rlang .data
#'
NULL


#' Fix the track ids for a single group (="movie")
#'
#'@param group_df The dataframe with data for a single group
#'
#' @export
createLUTGroup <- function(group_df) {
  groupIndList <- split(group_df, group_df$groupInd) %>% map(select, -.data$groupInd)
  p <- progressr::progressor(steps = length(groupIndList))

  p(str_glue("time 1/{length(groupIndList)}"))
  groupIndList[[1]] <- groupIndList[[1]] %>%
    mutate(cid = .data$obj_num, uid = .data$obj_num, alt_obj_num= as.character(.data$cid)) %>%
    select(-.data$par_obj_num)

  for(i in 2:length(groupIndList)) {
    p(str_glue("time {i}/{length(groupIndList)}"))

    # find the new cells (which have par_obj_num) and assign them a new cid
    new <- groupIndList[[i]] %>%
      filter(.data$par_obj_num == 0) %>%
      mutate(cid = row_number() + max(groupIndList[[i-1]]$cid),
             uid = row_number() + max(groupIndList[[i-1]]$uid),
             alt_obj_num = as.character(.data$cid)) %>%
      select(-.data$par_obj_num)

    # find cells that were present in the previous time frame, join them to previous info,
    # check for duplicate parent objects
    cont <- groupIndList[[i]] %>%
      filter(.data$par_obj_num != 0) %>%
      left_join(groupIndList[[i-1]], by = c("par_obj_num" = "obj_num")) %>%
      add_count(.data$par_obj_num)

    # first process those object who don't share parent object (they are easiest,
    # since we can just keep the values from the previous time frame)
    cont_single <- cont %>%
      filter(.data$n == 1) %>% # non-shared parent
      select(-.data$n, -.data$par_obj_num)

    # now the objects that share parents
    cont_multi <- cont %>%
      filter(.data$n > 1) %>%  # shared parents
      select(-.data$n) %>%
      group_by(.data$par_obj_num) %>%
      mutate(alt_obj_num = paste(.data$alt_obj_num, row_number(), sep = ".")) %>% # add suffix
      ungroup() %>%
      mutate(uid = row_number() + max(groupIndList[[i-1]]$uid)) %>% # give these cells new uids
      select(-.data$par_obj_num)

    # put together and update time frame in list
    groupIndList[[i]] <- bind_rows(new, cont_single, cont_multi) %>% arrange(.data$obj_num)

  }

  bind_rows(groupIndList, .id = "groupInd") %>%
    mutate(groupInd = as.numeric(.data$groupInd)) %>%
    relocate(.data$groupInd)

}


#' Fix the track ids for multiple group
#'
#' Optionally in parallel. (doesn't handle plate ID or other column names yet)
#'
#' @param data The dataframe with groupNumber, groupInd, par_obj_num, obj_num
#'
#' @export
createLUT <- function(data) {
  data_nested <- data %>%
    select(.data$groupNumber, .data$groupInd, .data$par_obj_num, .data$obj_num) %>%
    nest(data = -.data$groupNumber)
  p <- progressr::progressor(steps = nrow(data_nested)+1)
  data_nested %>%
    mutate(data = furrr::future_imap(.data$data, function(x,i) {
      p(str_glue("group {i}/{nrow(data_nested)}"))
      createLUTGroup(x)
    })
    )
  p()
  data_nested %>%
    unnest(cols = .data$data)
}
