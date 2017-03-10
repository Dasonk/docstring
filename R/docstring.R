
#' @import utils
docstring_to_roxygen <- function(fun, funname = as.character(substitute(fun))){
    
    # Right now this extracts any roxygen style comments
    # and they don't need to be consecutive.  I'm not sure
    # if I want to change that or not. Oh well.
    # The code then removes the leading spaces because our intent is
    # to put this above a generated function to be valid roxygen
    # style comments
    values <- capture.output(print(fun))
    roxy_ids <- grepl("^[[:space:]]*#\'", values)
    roxy_strings <- values[roxy_ids]
    roxy_strings <- gsub("^[[:space:]]*", "", roxy_strings)
    
    roxy <- paste0(roxy_strings, collapse = "\n")
    
    
    funargs <- capture.output(args(fun))
    # capture.output(args(fun)) doesn't show the function definition
    # instead just giving something of the form:
    #
    # function(x, y, ...)
    # NULL
    #
    # but what we want in our file is something that looks like:
    #
    # funname <- function(x, y, ...)
    # NULL
    #
    # So let's add the function definition back in
    funargs[1] <- paste(funname, "<-", funargs[1])
    
    # Combine our extracted roxygen and the function definition
    roxytext <- paste(c(roxy, funargs), collapse = "\n")
    return(roxytext)
}


#' Display a docstring
#' 
#' Display a docstring using R's built in help file viewer.
#' 
#' @param fun The function that has the docstring you would like to display
#' @param default_title The title you would like to display if no title is detected
#' in the docstring itself. NOT YET IMPLEMENTED
#' @param warnings logical Whether you want warning messages displayed
#' in the console. NOT YET IMPLEMENTED.
#' @export
#' @import roxygen2
#' @import utils
docstring <- function(fun, default_title = "Title not detected", warnings = TRUE){
    
    funname <- as.character(substitute(fun))
    
    # Extract the roxygen style comments from the function's code
    roxytext <- docstring_to_roxygen(fun, funname = funname)
    
    # The general approach is to create a shell of a package
    # and create an R file in the R directory in which we write
    # out the roxygen comments followed by a minimal function
    # definition. We roxygenize the fake package and then
    # view the resulting help file. Afterwards we remove
    # the files and folders we create
    
    
    tdir <- tempdir()
    packagedir <- file.path(tdir, "TempPackage")
    if(file.exists(packagedir)){
        unlink(packagedir, recursive = TRUE)
    }
    on.exit(unlink(packagedir, recursive = TRUE))
    
    # We need 
    
    j <- new.env(parent = emptyenv())
    j$a <- 0
    package.skeleton(name = "TempPackage", path = tdir, environment = j)
    
    if(!file.exists(file.path(packagedir, "R"))){
        dir.create(file.path(packagedir, "R"))
    } 
    
    tfile <- file.path(packagedir, "R", paste0(funname, ".R"))
    # tfile <- tempfile(pattern = funname, 
    #                   fileext = ".R", 
    #                   tmpdir = paste0(packagedir, "/R"))
    cat(roxytext, file = tfile)
    
    roxygenize(packagedir, "rd")
    
    file <- file.path(packagedir, "man", paste0(funname, ".Rd"))
    
    temp <- tools::Rd2HTML(file, tempfile(fileext = ".html"))
    
    browseURL(temp)
    
    return(invisible())
}
