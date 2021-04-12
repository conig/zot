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

  out <- tibble::tibble(x[,c("citekey","year", "title", "authors", "journal", "note")])
  out[order(-out$year, out$authors),]
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
  lib <- read_library(json)
  date <- paste0("Updated: ", format(file.info(json)$atime, format = "%y-%m-%d, %I:%M%p"))
  title = "My library"
  if(is.null(path)) path <- tempfile(fileext = ".html")

  rmarkdown::render(system.file("zotero_notes.Rmd", package = "zot"),
                    output_file = path,
                    quiet = T)
  system2("open",path)

}
