% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cyto_channels-helpers.R
\name{cyto_channels}
\alias{cyto_channels}
\title{Extract channel names}
\usage{
cyto_channels(x, select = NULL, exclude = NULL)
}
\arguments{
\item{x}{object of class \code{\link[flowCore:flowFrame-class]{flowFrame}},
\code{\link[flowCore:flowSet-class]{flowSet}},
\code{\link[flowWorkspace:GatingHierarchy-class]{GatingHierarchy}} or
\code{\link[flowWorkspace:GatingSet-class]{GatingSet}}.}

\item{select}{vector of channel names to select.}

\item{exclude}{vector of channel names to exclude.}
}
\value{
vector of channel names.
}
\description{
Simply a wrapper around \code{colnames} to extract the channels associated
with a \code{flowFrame}, \code{flowSet}, \code{GatingHierarchy} or
\code{GatingSet}.
}
\examples{

# Load in CytoExploreRData to access data
library(CytoExploreRData)

# Activation flowSet
fs <- Activation

# Activation GatingSet
gs <- GatingSet(fs)

# flowFrame
cyto_channels(fs[[1]])

# flowSet
cyto_channels(fs)

# GatingHierarchy
cyto_channels(gs[[1]])

# GatingSet - exclude FSC & SSC channels
cyto_channels(gs, exclude = c("FSC","SSC"))

}
\seealso{
\code{\link{cyto_fluor_channels}}
}
\author{
Dillon Hammill, \email{Dillon.Hammill@anu.edu.au}
}
