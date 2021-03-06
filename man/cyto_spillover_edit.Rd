% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cyto_spillover_edit.R
\name{cyto_spillover_edit}
\alias{cyto_spillover_edit}
\alias{cyto_spillover_edit.GatingSet}
\alias{cyto_spillover_edit.flowSet}
\title{Interactively Edit Spillover Matrices in Real-Time}
\usage{
\method{cyto_spillover_edit}{GatingSet}(
  x,
  parent = NULL,
  channel_match = NULL,
  spillover = NULL,
  axes_trans = NULL,
  axes_limits = "machine",
  display = 2000,
  point_size = 3,
  axes_text_size = 1.7,
  axes_label_text_size = 2,
  title_text_size = 2,
  header_text_size = 1.5,
  ...
)

\method{cyto_spillover_edit}{flowSet}(
  x,
  channel_match = NULL,
  spillover = NULL,
  axes_trans = NULL,
  axes_limits = "machine",
  display = 2000,
  point_size = 3,
  axes_text_size = 1.7,
  axes_label_text_size = 2,
  title_text_size = 2,
  header_text_size = 1.5,
  ...
)
}
\arguments{
\item{x}{an object of class \code{flowSet} or \code{GatingSet}.}

\item{parent}{name of the parent population to plot when a \code{GatingSet}
object is supplied.}

\item{channel_match}{name of csv file matching the name of each sample to a
fluorescent channel. The \code{channel_match} file must contain the columns
"name" and "channel". The \code{channel_match} file not required to use
\code{cyto_spillover_edit} but is used internally to automatically select
channels associated with the selcted samples.}

\item{spillover}{name of a square spillover matrix csv file or spillover
matrix to edit. Setting \code{spillover} to NULL (the default) will result
in extraction of the spillover matrix directly from the supplied samples
(i.e. edit the spillover matrix constructed on the cytometer).}

\item{axes_trans}{an object of class \code{transformerList} containing
transformers to used to transform the fluorescent channels of
the samples for visualisation.}

\item{axes_limits}{options include \code{"auto"}, \code{"data"} or
\code{"machine"} to use optimised, data or machine limits respectively. Set
to \code{"machine"} by default to use entire axes ranges.}

\item{display}{numeric passed to \code{cyto_plot} to control the number of
events to be displayed in the plots, set to 2000 events by default.}

\item{point_size}{integer passed to \code{cyto_plot} to control the size of
the points in all plots, set to 3 by default.}

\item{axes_text_size}{numeric pasedd to \code{cyto_plot} to control the size
of axes text, set to 1.7 by default.}

\item{axes_label_text_size}{numeric passed to \code{cyto_plot} to control the
text size of axes labels, set to 2 by default.}

\item{title_text_size}{numeric passed to \code{cyto_plot} to control the text
size of titles above each plot, set to 2 by default.}

\item{header_text_size}{numeric passed to \code{cyto_plot_compensation} to
control size of the header text, set to 1.5 by default.}

\item{...}{additional arguments passed to \code{cyto_plot}.}
}
\value{
edited spillover matrix and save to designated \code{spillover} csv
  file. Saved filename defaults to \code{date-Spillover-Matrix.csv} is not
  specified.
}
\description{
\code{cyto_spillover_edit} provides an interactive shiny interface for
editing fluorescent spillover matrices.
}
\details{
\code{cyto_spillover_edit} takes on either a
\code{\link[flowCore:flowSet-class]{flowSet}} or
\code{\link[flowWorkspace:GatingSet-class]{GatingSet}} containing
compensation controls and/or samples. It is recommended that samples be
pre-gated based on FSC and SSC parameters to obtain a homogeneous population
for calculation of fluorescent spillover. The compensation controls should
also be transformed prior to using \code{cyto_spillover_edit}.

Users begin by selecting the unstained control and a stained control from
dropdown menus of sample names. \code{cyto_spillover_edit} leverages
\code{cyto_plot} to plot the stained sample and overlay the unstained control
in black. Users should then select the channel associated with the selected
control on the \code{x axis} and go through all other channels on the \code{y
axis}.

The displayed spillover matrix is extracted directly from the
\code{\link[flowCore:flowSet-class]{flowSet}} or
\code{\link[flowWorkspace:GatingSet-class]{GatingSet}} unless another
spillover matrix is supplied through the spillover argument. To edit the
spillover matrix simply modify the appropriate cell in the the table. The new
spillover matrix will be re-applied to the samples with each edit and
automatically re-plotted so you can track changes in real-time.

To aid in selection of an appropriate spillover value, the median fluorescent
intensity of the unstained control is indicated by a red line and median
fluorescent intensity of the stained control is tracked with a purple line.
These features can be turned off by de-selecting the check boxes. Changes to
the spillover matrix are automatically saved to a csv file called
\code{"date-Spillover-Matrix.csv"} in the case where the \code{spillover} is
not specified or to the same name as the specified \code{spillover}.
}
\seealso{
\code{\link{cyto_spillover_compute}}

\code{\link{cyto_plot_compensation}}

\code{\link{cyto_plot}}
}
\author{
Dillon Hammill, \email{Dillon.Hammill@anu.edu.au}
}
