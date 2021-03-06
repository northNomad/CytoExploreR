## CYTO_STATS_COMPUTE ----------------------------------------------------------

# bind_rows warnings - columns converted to character class

#' Compute, export and save statistics
#'
#' @param x object of class \code{\link[flowCore:flowFrame-class]{flowFrame}},
#'   \code{\link[flowCore:flowSet-class]{flowSet}},
#'   \code{\link[flowWorkspace:GatingHierarchy-class]{GatingHierarchy}} or
#'   \code{\link[flowWorkspace:GatingSet-class]{GatingSet}}.
#' @param alias name(s) of the population(s) for which the statistic should be
#'   calculated when a \code{GatingHierarchy} or \code{GatingSet} is supplied.
#' @param parent name(s) of the parent population(s) used calculate population
#'   frequencies when a \code{GatingHierarchy} or \code{GatingSet} object is
#'   supplied. The frequency of alias in each parent will be returned as a
#'   percentage.
#' @param channels names of of channels for which statistic should be
#'   calculated, set to all channels by default.
#' @param trans object of class
#'   \code{\link[flowWorkspace:transformerList]{transformerList}} used to
#'   transfom the channels of the supplied data. The \code{transformerList} is
#'   required to return the data to the original linear scale when calculating
#'   statistics.
#' @param stat name of the statistic to calculate, options include
#'   \code{"count"}, \code{"freq"}, \code{"median"}, \code{"mode"},
#'   \code{"mean"}, \code{"geo mean"}, \code{"CV"}, or \code{"freq"}.
#' @param gate object of class \code{rectangleGate}, \code{polygonGate} or
#'   \code{ellipsoidGate} to apply to \code{flowFrame} or \code{flowSet}
#'   objects prior to computing statistics.
#' @param format indicates whether the data should be returned in the
#'   \code{"wide"} or \code{"long"} format, set to the \code{"long"} format by
#'   default.
#' @param save_as name of a csv file to which the statistical results should be
#'   saved.
#' @param density_smooth smoothing parameter passed to
#'   \code{\link[stats:density]{density}} when calculating mode, set to 1.5 by
#'   default.
#' @param ... not in use.
#'
#' @return a tibble containing the computed statistics in the wide or long
#'   format.
#'
#' @author Dillon Hammill, \email{Dillon.Hammill@anu.edu.au}
#'
#'
#' @importFrom utils write.csv
#' @importFrom dplyr bind_rows bind_cols select %>%
#' @importFrom tidyr spread gather
#' @importFrom tibble as_tibble add_column remove_rownames
#' @importFrom tools file_ext
#' @importFrom methods is
#'
#' @examples
#' library(CytoExploreRData)
#'
#' # Load in samples
#' fs <- Activation
#' gs <- GatingSet(fs)
#'
#' # Apply compensation
#' gs <- compensate(gs, fs[[1]]@description$SPILL)
#'
#' # Transform fluorescent channels
#' trans <- estimateLogicle(gs[[32]], cyto_fluor_channels(gs))
#' gs <- transform(gs, trans)
#'
#' # Gate using cyto_gate_draw
#' gt <- Activation_gatingTemplate
#' gt_gating(gt, gs)
#'
#' # Compute statistics - median
#' cyto_stats_compute(gs,
#'   alias = "T Cells",
#'   channels = c("Alexa Fluor 488-A", "PE-A"),
#'   stat = "median",
#'   save = FALSE
#' )
#'
#' # Compute population frequencies and save to csv file
#' cyto_stats_compute(gs,
#'   alias = c("CD4 T Cells", "CD8 T Cells"),
#'   parent = c("Live Cells", "T Cells"),
#'   stat = "freq",
#'   save_as = "Population-Frequencies"
#' )
#'
#' @name cyto_stats_compute
NULL

#' @noRd
#' @export
cyto_stats_compute <- function(x, ...){
  UseMethod("cyto_stats_compute")
}

#' @rdname cyto_stats_compute
#' @export
cyto_stats_compute.GatingSet <- function(x,
                                         alias = NULL,
                                         parent = NULL,
                                         channels = NULL,
                                         trans = NA,
                                         stat = "median",
                                         format = "long",
                                         save_as = NULL,
                                         density_smooth = 0.6, ...) {
  
  # Check statistic
  stat <- .cyto_stat_check(stat = stat)
  
  # Assign x to gs
  gs <- x
  
  # Get trans if not supplied
  trans <- cyto_transformer_extract(gs)
  
  # Alias must be supplied
  if (is.null(alias)) {
    stop("Supply the name of the population to 'alias'.")
  }
  
  # Make calls to GatingHierarchy method
  res <- lapply(seq(1, length(gs)), function(x) {
    cyto_stats_compute(gs[[x]],
                       parent = parent,
                       alias = alias,
                       channels = channels,
                       trans = trans,
                       stat = stat,
                       format = format,
                       save_as = NULL,
                       density_smooth = density_smooth
    )
  })
  res <- suppressWarnings(do.call("bind_rows", res))
  
  # Save results to csv file
  if (!is.null(save_as)) {
    if (file_ext(save_as) == "") {
      save_as <- paste0(save_as, ".csv")
    }
    write.csv(res, save_as, row.names = FALSE)
  }
  
  return(res)
}

#' @rdname cyto_stats_compute
#' @export
cyto_stats_compute.GatingHierarchy <- function(x,
                                               alias = NULL,
                                               parent = NULL,
                                               channels = NULL,
                                               trans = NA,
                                               stat = "median",
                                               format = "long",
                                               save_as = NULL,
                                               density_smooth = 0.6, ...) {
  
  # Check statistic
  stat <- .cyto_stat_check(stat = stat)
  
  # Assign x to gh
  gh <- x
  
  # Get trans if not supplied
  trans <- cyto_transformer_extract(gh)
  
  # Alias must be supplied
  if (is.null(alias)) {
    stop("Supply the name of the population to 'alias'.")
  }
  
  # Extract population(s) - list of flowFrames
  alias_frames <- lapply(alias, function(x) cyto_extract(gh, x))
  
  # Extract parent population(s) - list of flowFrames
  if (stat == "freq") {
    if (is.null(parent)) {
      message(
        paste(
          "Calculating frequency of 'root' as no 'parent'",
          "population(s) were specified."
        )
      )
      parent <- "root"
    }
    parent_frames <- lapply(parent, function(x) cyto_extract(gh, x))
  }
  
  # Extract pData
  pd <- cyto_details(gh)
  pd <- as_tibble(remove_rownames(pData(gh)))
  pd$name <- as.factor(pd$name) # remove weird <I(chr)> class
  
  # Repeat row alias times - add stats as columns
  pd <- suppressWarnings(do.call(
    "bind_rows",
    replicate(length(alias),
              pd,
              simplify = FALSE
    )
  ))
  
  # Add Population column
  pd <- add_column(pd, Population = alias)
  
  # Statistics
  if (stat == "freq") {
    
    # Calculate count statistic for each parent population
    parent_counts <- lapply(seq(1, length(parent)), function(x) {
      cnt <- cyto_stats_compute(parent_frames[[x]],
                                channels = channels,
                                trans = trans,
                                stat = "count"
      )
      
      # Repeat row alias times
      cnt <- suppressWarnings(do.call(
        "bind_rows",
        replicate(length(alias),
                  cnt,
                  simplify = FALSE
        )
      )[, 2])
      
      return(cnt)
    })
    parent_counts <- suppressWarnings(do.call("bind_cols", parent_counts))
    colnames(parent_counts) <- parent
    
    # Add parent counts to pd
    pd <- bind_cols(pd, parent_counts)
    
    # Caclulate counts for each alias
    alias_counts <- lapply(seq(1, length(alias)), function(x) {
      cnt <- cyto_stats_compute(alias_frames[[x]],
                                channels = channels,
                                trans = trans,
                                stat = "count"
      )[, 2]
      
      return(cnt)
    })
    alias_counts <- suppressWarnings(do.call("bind_rows", alias_counts))
    
    # Repeat alias_counts column parent times
    alias_counts <- alias_counts[, rep(1, length(parent))]
    colnames(alias_counts) <- parent
    
    # alias / parent * 100
    lapply(parent, function(x) {
      pd[, x] <<- alias_counts[, x] / pd[, x] * 100
    })
    res <- pd
    
    # Covert to long format
    if (format == "long") {
      res <- res %>%
        gather(
          "Parent",
          "Frequency",
          seq(ncol(res) - length(parent) + 1, ncol(res))
        )
    }
  } else {
    
    # Rbind results for each population in long format
    res <- lapply(seq(1, length(alias)), function(x) {
      dat <- cyto_stats_compute(alias_frames[[x]],
                                channels = channels,
                                trans = trans,
                                stat = stat,
                                format = "wide",
                                density_smooth = density_smooth
      )
    })
    res <- suppressWarnings(do.call("bind_rows", res))
    
    # Cbind with pd
    res <- bind_cols(pd, res[, -1])
    
    # R CMD CHECK NOTES
    Population <- NULL
    count <- NULL
    Marker <- NULL
    
    # Convert count statistics to wide format
    if (stat == "count" & format == "wide") {
      res <- res %>%
        spread(Population, count)
    }
    
    
    # Convert to long format
    if (format == "long") {
      res <- res %>%
        gather(
          Marker,
          !!.cyto_stat_name(stat),
          seq(ncol(pd) + 1, ncol(res))
        )
    }
  }
  
  # Save results
  if (!is.null(save_as)) {
    if (file_ext(save_as) == "") {
      save_as <- paste0(save_as, ".csv")
    }
    write.csv(res, save_as, row.names = FALSE)
  }
  
  return(res)
}

#' @rdname cyto_stats_compute
#' @export
#' @export
cyto_stats_compute.flowSet <- function(x,
                                       channels = NULL,
                                       trans = NA,
                                       stat = "median",
                                       gate = NA,
                                       format = "long",
                                       density_smooth = 0.6, ...) {

  # Check statistic
  stat <- .cyto_stat_check(stat = stat)

  # Assign x to fs
  fs <- x

  # cyto_stats_compute
  res <- fsApply(fs, function(fr) {
    cyto_stats_compute(fr,
      channels = channels,
      trans = trans,
      stat = stat,
      gate = gate,
      density_smooth = density_smooth,
      format = "wide"
    )
  })
  res <- suppressWarnings(do.call("bind_rows", res))

  # Extract pData -> tibble
  pd <- cyto_details(fs)
  name_class <- class(pd$name)
  pd <- as_tibble(remove_rownames(pd))
  class(pd$name) <- name_class

  # cbind pd with res
  res <- bind_cols(pd, res[, -1])

  # Convert to long format
  if (format == "long" &
    stat != "count" &
    length(channels) > 1) {
    mn <- ncol(pd) + 1
    mx <- ncol(res)

    res <- res %>%
      gather(
        key = "Marker",
        value = "Value",
        !!mn:mx
      )
    colnames(res)[ncol(res)] <- .cyto_stat_name(stat)
  }

  return(res)
}

#' @rdname cyto_stats_compute
#' @export
cyto_stats_compute.flowFrame <- function(x,
                                         channels = NULL,
                                         trans = NA,
                                         stat = "median",
                                         gate = NA,
                                         format = "long",
                                         density_smooth = 0.6, ...) {

  # Check statistic
  stat <- .cyto_stat_check(stat = stat)

  # Assign x to fr
  fr <- x

  # Channels
  if (is.null(channels)) {
    channels <- BiocGenerics::colnames(fr)
  } else {
    channels <- cyto_channels_extract(
      x = fr,
      channels = channels,
      plot = FALSE
    )
  }

  # Transformations
  if (.all_na(trans) & stat %in%
    c("mean", "median", "mode", "geo mean", "CV")) {
    message(
      paste(
        "'trans' missing - statistics will be returned on the",
        "current scale."
      )
    )
    trans <- NA
  # Check transformerList is supplied
  }else if(!.all_na(trans)){
    # transformerLists only
    if(!is(trans, "transformerList")){
      stop("'trans' must be an object of class transformerList!")
    }
  }
  
  # Statistics
  if (stat == "count") {
    res <- .cyto_count(fr,
      gate = gate
    )
  } else if (stat == "mean") {
    res <- suppressMessages(.cyto_mean(fr,
      channels = channels,
      trans = trans,
      gate = gate
    ))
  } else if (stat == "geo mean") {
    res <- suppressMessages(.cyto_geometric_mean(fr,
      channels = channels,
      trans = trans,
      gate = gate
    ))
  } else if (stat == "median") {
    res <- suppressMessages(.cyto_median(fr,
      channels = channels,
      trans = trans,
      gate = gate
    ))
  } else if (stat == "mode") {
    res <- suppressMessages(.cyto_mode(fr,
      channels = channels,
      trans = trans,
      gate = gate,
      density_smooth = density_smooth
    ))
  } else if (stat == "CV") {
    res <- suppressMessages(.cyto_CV(fr,
      channels = channels,
      trans = trans,
      gate = gate
    ))
  } else if (stat == "freq") {

    # Calculate statistics
    res <- .cyto_freq(x,
      gate = gate
    )
  }

  # Convert to long format
  if (format == "long" &
    !stat %in% c("count", "freq") &
    length(channels) > 1) {
    res <- res %>%
      gather(
        key = "Marker",
        value = "Value"
      )
    colnames(res)[ncol(res)] <- .cyto_stat_name(stat)
  }

  # Combine with pData
  pd <- tibble("name" = rep(identifier(fr), nrow(res)))
  res <- bind_cols(pd, res)

  return(res)
}

## .CYTO_STAT_CHECK ------------------------------------------------------------

#' Check Statistic for cyto_stats_compute
#'
#' @param stat cyto_stats_compute statistic.
#'
#' @author Dillon Hammill, \email{Dillon.Hammill@anu.edu.au}
#'
#' @noRd
.cyto_stat_check <- function(stat) {

  if(.all_na(stat)){
    return(NA)
  }
  
  if (!stat %in% c(
    "mean",
    "Mean",
    "median",
    "Median",
    "mode",
    "Mode",
    "count",
    "Count",
    "events",
    "Events",
    "percent",
    "Percent",
    "freq",
    "Freq",
    "geo mean",
    "Geo mean",
    "Geo Mean",
    "CV",
    "cv"
  )) {
    stop("Supplied statistic not supported.")
  }

  if (stat %in% c("mean", "Mean")) {
    stat <- "mean"
  } else if (stat %in% c("median", "Median")) {
    stat <- "median"
  } else if (stat %in% c("mode", "Mode")) {
    stat <- "mode"
  } else if (stat %in% c("count", "Count", "events", "Events")) {
    stat <- "count"
  } else if (stat %in% c("percent", "Percent", "freq", "Freq")) {
    stat <- "freq"
  } else if (stat %in% c("geo mean", "Geo mean", "Geo Mean")) {
    stat <- "geo mean"
  } else if (stat %in% c("cv", "CV")) {
    stat <- "CV"
  }

  return(stat)
}

## .CYTO_STAT_NAME -------------------------------------------------------------

#' Get column name for statistic
#'
#' @param x statistic.
#'
#' @return name of statistics to include as column name for long data format.
#'
#' @author Dillon Hammill, \email{Dillon.Hammill@anu.edu.au}
#'
#' @noRd
.cyto_stat_name <- function(x) {
  if (x == "count") {
    nm <- "Count"
  } else if (x == "mean") {
    nm <- "MFI"
  } else if (x == "geo mean") {
    nm <- "GMFI"
  } else if (x == "median") {
    nm <- "MedFI"
  } else if (x == "mode") {
    nm <- "ModFI"
  } else if (x == "CV") {
    nm <- "CV"
  } else if (x == "percent") {
    nm <- "Percent"
  }
  return(nm)
}
