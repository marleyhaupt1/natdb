#' @importFrom stats model.matrix

#' Unzips a file from a downloaded zip file
#' @param file name of file to be extracted from zip
#' @param zip location and name of zip file (e.g.,
#'     ~/Downlaods/a_file.zip)
#' @param to.save.dir directory to save resulting file (DEFAULT: a new
#'     temporary directory will be used)
#' @param to.save.name name to save the file as (DEFAULT: it will be
#'     named paste(zip,file, sep='_'))
#' @return Complete path to unzipped file
#' @importFrom utils unzip
#' @importFrom reshape2 melt
.unzip <- function(file, zip, to.save.dir, to.save.name){
    if(missing(to.save.dir))
        to.save.dir <- tempdir()
    if(missing(to.save.name))
        to.save.name <- file
    
    files <- unzip(zip, list=TRUE)
    if(!file %in% files$Name)
        stop("Required file not in zipfile ", zip)
    
    file <- unzip(zip, file)
    file.rename(file, file.path(to.save.dir, to.save.name))
    return(file.path(to.save.dir, to.save.name))
}

.fac.sim <- function(x){
    x <- Filter(Negate(is.na), x)
    x <- x[x != "" & x != " "]
    x <- unique(x)
    return(paste(x,collapse="_"))
}
.expand.factor <- function(factor_to_expand, name){
    names <- rep(name, length(unique(factor_to_expand)))
    output <- model.matrix(~factor_to_expand-1)
    colnames(output) <- paste(names, gsub("factor_to_expand", "", colnames(output)), sep="_")
    return(as.data.frame(output))
}
.df.melt <- function(x, species, units){
    if(!"metadata" %in% names(x))
        x$metadata <- NA
    if(missing(units)){
        units <- setNames(rep(NA, length(names(x))), names(x))
    } else {
        units <- setNames(units, setdiff(names(x),c(species,"metadata")))
    }
    numeric <- x[,sapply(x, is.numeric) | names(x) %in% c(species,"metadata")]
    if(ncol(numeric) > 2){
        numeric <- melt(numeric, id.vars=c(species,"metadata"))
        numeric <- numeric[!is.na(numeric$value),]
        names(numeric)[1] <- "species"
        numeric$units <- units[numeric$variable]
    } else numeric <- NULL
    character <- x[,sapply(x, Negate(is.numeric)) | names(x) %in% c(species,"metadata")]
    if(ncol(character) > 2){
        character <- melt(character, id.vars=c(species,"metadata"))
        character <- character[!is.na(character$value),]
        names(character)[1] <- "species"
        character$units <- units[character$variable]
    } else character <- NULL
    return(list(numeric=numeric,character=character))
}
.download <- function(url, dir, save.name, cache=TRUE){
    destination <- file.path(dir, save.name)
    suffix <- .file.suffix(url, 4)
    
    if(cache==TRUE & file.exists(destination)){
        if(!is.na(suffix))
            attr(destination, "suffix") <- suffix
        return(destination)
    }
    
    result <- download.file(url, destination, quiet=TRUE)
    if(result != 0)
        stop("Error code", result, " downloading file; file may not exist")
    
    if(!is.na(suffix))
        attr(destination, "suffix") <- suffix
    return(destination)
}
.save.name <- function(doi, save.name, file){
    if(is.na(save.name)){
        save.name <- paste(doi,file, sep="_")
        save.name <- gsub(.Platform$file.sep, "_", save.name, fixed=TRUE)
    }
    return(save.name)
}
.grep.url <- function(url, regexp, which=1){
    html <- as.character(GET(url))
    return(.grep.text(html, regexp, which))
}
.grep.text <- function(text, regexp, which=1){
    links <- gregexpr(regexp, text)
    if(which > length(links[[1]]))
        stop("SI number '", which, "' greater than number of detected SIs (", length(links[[1]]), ")")
    pos <- as.numeric(links[[1]][which])
    return(substr(text, pos, pos+attr(links[[1]], "match.length")[which]-1))
}
.file.suffix <- function(text, max.length=4){
    suffix <- .grep.text(text, "[a-zA-Z]+$")
    if(nchar(suffix) <= max.length & nchar(suffix) > 0)
        return(suffix)
    return(NA)
}
