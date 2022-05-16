#' zot_year
#'
#' Extract year from zotero free-text dates
#' @param x zot date string

zot_year <- function(x){
  as.numeric(sapply(stringr::str_extract_all(x, "\\d{4}"), function(x)
    if (length(x) == 0)
      NA
    else
      x[[1]]))
}

get_pdf_path <- function(x){
  ret <- x$path[grepl("\\.pdf$", x$path)]
  if(length(ret) == 0) return(NA)
  ret[[1]]
}


#' read_library
#'
#' read betterbibtex json library
#' @param path path to better biblatex debug json file

read_library <- function(path){
  x <- jsonlite::fromJSON(path)$items
  x$journal <- x$publicationTitle
  x$authors <- as.character(sapply(x$creators, get_author))
  x$authors[x$authors == "NULL"] <- ""
  x$year <- zot_year(x$date)

  x$note <- as.character(sapply(x$notes, get_notes))
  x$note[x$note == "character(0)"] <- ""
  x$pdf <- unlist(lapply(x$attachments, get_pdf_path))

  y <- x[!is.na(x$pdf), ]

  x$title[!is.na(x$pdf)] = glue::glue('<a href="{y$pdf}" target="_blank">{y$title}</a>')

  out <- tibble::tibble(x[,c("citekey","year", "title", "authors", "journal", "note")])
  out <- out[order(-out$year, out$authors),]
  out
}


get_author <- function(a){

  if(length(a) == 0){
    return("-")
  }

  if(nrow(a) == 1){
    return(a$lastName)
  }

  if(nrow(a) == 2){
    return(paste(a$lastName, collapse  = " & "))
  }

  #else

  paste(a$lastName[1], "et al.")

}

get_notes <- function(n){
  paste(n$note, collapse = "\n")
}

#' note
#'
#' Create zotero notes and open them.
#' @param path path to destination file.
#' @param json source json
#' @export

note <- function(path = NULL, json = NULL){
  if(is.null(json)) json <- system.file("My Library.json", package = "zot")
  if(json == ""){
    folder_path <- system.file(package = "zot")
    stop("I couldn't find 'My Library.json' at ", folder_path,"/")
  }
  check_setup(json)

  lib <- read_library(json)
  date <- paste0("Updated: ", format(file.info(json)$mtime, format = "%y-%m-%d, %I:%M%p"))
  title = "My library"
  if(is.null(path)) path <- tempfile(fileext = ".html")

  rmarkdown::render(system.file("zotero_notes.Rmd", package = "zot"),
                    output_file = path,
                    quiet = T)
  system2("open",path)
}

#' check_setup
#'
#' Check if zot is set up correctly
#' @export

check_setup <- function(path = NULL){
  if(is.null(path)) path <-
    file.path(system.file("", package = "zot"), "My Library.json")

  if(!file.exists(path)){
    stop("My Library.json was not found. Please save a BetterBibTeX JSON file to location:\n ", path)
  }

  item <- jsonlite::read_json(path)
  if(item$config$label != "BetterBibTeX JSON") stop("My Library.json must be of class BetterBibTex JSON. The supported file is ", item$config$label)
  TRUE

}
