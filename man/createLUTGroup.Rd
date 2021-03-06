% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/CPTraceR.R
\name{createLUTGroup}
\alias{createLUTGroup}
\title{Fix the track ids for a single group (="movie")}
\usage{
createLUTGroup(data, frame_var, obj_var, par_obj_var)
}
\arguments{
\item{data}{The data frame with data for a single group}

\item{frame_var}{The variable which identifies separate frames in the group. Most commonly 'groupId'.}

\item{obj_var}{The variable with the object number, for example, 'Nuclei_Number_Object_Number'}

\item{par_obj_var}{The variable indicating the parent object number in the previous time frame,
for example 'Nuclei_TrackObjects_ParentObjectNumber_30'}
}
\description{
Fix the track ids for a single group (="movie")
}
\examples{
\dontrun{
createLUTGroup(data,
               frame_var = groupInd,
               obj_var = Nuclei_Number_Object_Number,
               par_obj_var = Nuclei_TrackObjects_ParentObjectNumber_30)
}

}
