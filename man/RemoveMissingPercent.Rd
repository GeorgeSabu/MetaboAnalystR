% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/general_proc_utils.R
\name{RemoveMissingPercent}
\alias{RemoveMissingPercent}
\title{Data processing: remove variables with missing values}
\usage{
RemoveMissingPercent(mSetObj, percent)
}
\arguments{
\item{mSetObj}{Input the name of the created mSetObj (see InitDataObjects)}

\item{percent}{Input the percentage cut-off you wish to use. For instance, 50 percent is represented by percent=0.5.}
}
\description{
Remove variables containing a user-defined percentage cut-off of missing values.
}
\author{
Jeff Xia \email{jeff.xia@mcgill.ca}
McGill University, Canada
License: GNU GPL (>= 2)
}
