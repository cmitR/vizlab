#' Ensure data is on the local file system
#' 
#' This function should be called from the generic, \code{readData()}. Reads
#' data from a file into R format.
#' 
#' @param viz.id the identifier for this data item in viz.yaml
#' @param ... other arguments passed to readData methods
#' 
#' @export
readData <- function(viz.id, ...) UseMethod("readData")

#' @param data.info content information for this viz.id from the viz.yaml
#' 
#' @rdname readData
#' @export
readData.default <- function(viz.id, data.info, ...) {
  # explain the problem if we're headed for infinite recursion
  if(class(viz.id) != 'character') 
    stop('could not find readData method for viz.id=', viz.id, ', reader=', class(viz.id))
  
  # get the reading information for this data ID from viz.yaml
  data.info <- getContentInfo(viz.id, no.match='NA')
  
  # routes subsequent calls to a specific readData method
  if(exists('customReader', data.info)) {
    sapply(file.path('scripts/read', dir('scripts/read')), source)
    class(viz.id) <- data.info$customReader
  } else {
    class(viz.id) <- switch(
      data.info$mimeType,
      "text/csv" = "csv",
      "text/tab-separated-values" = "csv",
      "text/yaml" = "yaml",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "excel",
      "custom")
  }
  
  # call the readData method applicable to this fetcher
  readData(viz.id=viz.id, data.info=data.info, ...)
}

#' \code{readData.csv} reads a csv file.
#'
#' @rdname readData
#' @export
readData.csv <- function(viz.id, data.info, ...) {
  if(!requireNamespace('data.table', quietly = TRUE)) stop("package data.table is required for readData.csv")
  x <- data.table::setDF(data.table::fread(data.info$location))
  x # assign to x first so it returns visibly
}

#' \code{readData.yaml} reads a yaml file.
#'
#' @rdname readData
#' @import yaml
#' @export
readData.yaml <- function(viz.id, data.info, ...) {
  yaml.load_file(data.info$location)
}

#' \code{readData.excel} reads the first spreadsheet of an Excel file.
#'
#' @rdname readData
#' @export
readData.excel <- function(viz.id, data.info, ...) {
  if(!requireNamespace('readxl', quietly = TRUE)) stop("package readxl is required for readData.excel")
  readxl::read_excel(data.info$location)
}