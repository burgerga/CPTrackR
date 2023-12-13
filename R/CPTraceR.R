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
#' @importFrom rlang .data :=
#'
NULL


#' Fix the track ids for a single group (="movie")
#'
#' @param data The data frame with data for a single group
#' @inheritParams createLUT
#'
#' @examples
#' \dontrun{
#' createLUTGroup(data,
#'                frame_var = groupInd,
#'                obj_var = Nuclei_Number_Object_Number,
#'                par_obj_var = Nuclei_TrackObjects_ParentObjectNumber_30)
#' }
#'
#' @export
createLUTGroup <- function(data, frame_var, obj_var, par_obj_var) {
groupIndList <- data %>%
    select({{frame_var}}, {{obj_var}}, {{par_obj_var}}) %>%
    arrange({{frame_var}}) %>%
    group_split({{frame_var}}) %>%
    as.list() # remove vctrs typing which doesn't allow replacing list entries with incompatible column layout
  p <- progressr::progressor(steps = length(groupIndList))

  p(str_glue("time 1/{length(groupIndList)}"))
  groupIndList[[1]] <- groupIndList[[1]] %>%
    mutate(cid = {{obj_var}}, uid = {{obj_var}}, alt_uid= as.character(.data$cid)) %>%
    select(-{{par_obj_var}})

  for(i in 2:length(groupIndList)) {
    p(str_glue("time {i}/{length(groupIndList)}"))

    # find the new cells (which have par_obj_num == 0) and assign them a new cid
    new <- groupIndList[[i]] %>%
      filter({{par_obj_var}} == 0) %>%
      mutate(cid = row_number() + max(groupIndList[[i-1]]$cid),
             uid = row_number() + max(groupIndList[[i-1]]$uid),
             alt_uid = as.character(.data$cid)) %>%
      select(-{{par_obj_var}})

    # find cells that were present in the previous time frame, join them to previous info,
    # check for duplicate parent objects
    cont <- groupIndList[[i]] %>%
      filter({{par_obj_var}} != 0) %>%
      left_join(groupIndList[[i-1]] %>%
                  rename("{{par_obj_var}}" := {{obj_var}}) %>%
                  select(-{{frame_var}}),
                by = c(rlang::as_name(enquo(par_obj_var)))) %>%
      add_count({{par_obj_var}})

    # first process those object who don't share parent object (they are easiest,
    # since we can just keep the values from the previous time frame)
    cont_single <- cont %>%
      filter(.data$n == 1) %>% # non-shared parent
      select(-"n", -{{par_obj_var}})

    # now the objects that share parents
    cont_multi <- cont %>%
      filter(.data$n > 1) %>%  # shared parents
      select(-"n") %>%
      group_by({{par_obj_var}}) %>%
      mutate(alt_uid = paste(.data$alt_uid, row_number(), sep = ".")) %>% # add suffix
      ungroup() %>%
      mutate(uid = row_number() + max(groupIndList[[i-1]]$uid, new$uid)) %>% # give these cells new uids
      select(-{{par_obj_var}})

    # put together and update time frame in list
    groupIndList[[i]] <- bind_rows(new, cont_single, cont_multi) %>% arrange(.data$uid)

  }

  bind_rows(groupIndList)
}


#' Fix the track ids for multiple group
#'
#',
#'
#' Optionally in parallel.
#'
#' @param data The data frame with cellprofiler data
#' @param group_vars The variable(s) which make up the movies for which the tracks should be fixed.
#' Most commonly 'groupNumber' but can also include plate id.
#' @param frame_var The variable which identifies separate frames in the group. Most commonly 'groupId'.
#' @param obj_var The variable with the object number, for example, 'Nuclei_Number_Object_Number'
#' @param par_obj_var The variable indicating the parent object number in the previous time frame,
#' for example 'Nuclei_TrackObjects_ParentObjectNumber_30'
#'
#' @examples
#' \dontrun{
#' createLUT(data,
#'           group_vars = groupNumber,
#'           frame_var = groupInd,
#'           obj_var = Nuclei_Number_Object_Number,
#'           par_obj_var = Nuclei_TrackObjects_ParentObjectNumber_30)
#'
#' with_progress({
#' lut <- createLUT(data,
#'                  group_vars = groupNumber,
#'                  frame_var = groupInd,
#'                  obj_var = Nuclei_Number_Object_Number,
#'                  par_obj_var = Nuclei_TrackObjects_ParentObjectNumber_30)
#' })
#' }
#'
#' @export
createLUT <- function(data, group_vars, frame_var, obj_var, par_obj_var) {
  data_nested <- data %>%
    select({{group_vars}}, {{frame_var}}, {{obj_var}}, {{par_obj_var}}) %>%
    nest(data = -{{group_vars}})

  p <- progressr::progressor(steps = nrow(data_nested) + 1)
  data_nested <- data_nested %>%
    mutate(data = furrr::future_imap(.data$data, function(x, i) {
      p(str_glue("group {i}/{nrow(data_nested)}"))
      createLUTGroup(x, {{frame_var}}, {{obj_var}}, {{par_obj_var}})
    }, .options = furrr::furrr_options(globals = c("createLUTGroup"),
                                       packages = c("dplyr","tidyr", "stringr", "purrr")))
    )
  p()

  data_nested %>%
    unnest(cols = .data$data)
}
