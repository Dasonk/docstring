
#' @importFrom utils capture.output
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
    roxy_text <- paste(c(roxy, funargs), collapse = "\n")
    return(roxy_text)
}


#' Display a docstring
#' 
#' Display a docstring using R's built in help file viewer.
#' 
#' @param fun The function that has the docstring you would like to display
#' @param default_title The title you would like to display if no title is detected
#' in the docstring itself. NOT YET IMPLEMENTED
#' 
#' @importFrom roxygen2 roxygenize
#' @importFrom utils capture.output
#' @importFrom utils package.skeleton
#' @importFrom utils browseURL
#' 
#' @export
docstring <- function(fun, default_title = "Title not detected"){
    
    fun_name <- as.character(substitute(fun))
    
    # Extract the roxygen style comments from the function's code
    roxy_text <- docstring_to_roxygen(fun, funname = fun_name)
    
    # The general approach is to create a shell of a package
    # and create an R file in the R directory in which we write
    # out the roxygen comments followed by a minimal function
    # definition. We roxygenize the fake package and then
    # view the resulting help file. Afterwards we remove
    # the files and folders we create
    
    temp_dir <- tempdir()
    package_name <- "TempPackage"
    package_dir <- file.path(temp_dir, package_name)
    if(file.exists(package_dir)){
        unlink(package_dir, recursive = TRUE)
    }

    j <- new.env(parent = emptyenv())
    j$a <- 0
    
    suppressMessages(package.skeleton(name = package_name, 
                                      path = temp_dir, 
                                      environment = j)
                     )
    
    on.exit(unlink(package_dir, recursive = TRUE)) # created w/ package.skeleton
    
    
    if(!file.exists(file.path(package_dir, "R"))){
        dir.create(file.path(package_dir, "R"))
    } 
    
    temp_file <- file.path(package_dir, "R", paste0(fun_name, ".R"))
    cat(roxy_text, file = temp_file)
    

    # roxygen uses cat to display the "Writing your_function.Rd" messages so
    # I figured capturing the output would be 'safer' than using sink and
    # diverting things. Oh well.
    output <- capture.output(suppressWarnings(suppressMessages(roxygenize(package_dir, "rd"))))

    
    generated_Rd_file <- file.path(package_dir, "man", paste0(fun_name, ".Rd"))
    
    
    ####################################
    # Everything before here should be the same regardless of display type
    ####################################
    
    isRStudio <- Sys.getenv("RSTUDIO") == "1"
    
    if(isRStudio){
        rstudioapi::previewRd(generated_Rd_file)
        # Workaround since the file doesn't get displayed if we don't give
        # Rstudio time to do it's thing before the directory get's deleted.
        Sys.sleep(1)
    }else{
        # Only supporting html for the time being apparently
        
        html_to_display <- tools::Rd2HTML(generated_Rd_file, tempfile(fileext = ".html"))
        browseURL(html_to_display)
    }
    
    
    return(invisible())
}
