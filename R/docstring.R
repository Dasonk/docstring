#' Attempts to pull out the docstring and turn them into valid
#' roxygen style comments formated in a way that it should
#' be able to be written directly to a file
#'
#' @return  character - the roxygen strings if there is a docstring, error if not
#' @importFrom utils capture.output
#' @noRd
docstring_to_roxygen <- function(fun, fun_name = as.character(substitute(fun)),
                                 default_title = "Title not detected", error = TRUE){

    # Right now this extracts any roxygen style comments
    # and they don't need to be consecutive.  I'm not sure
    # if I want to change that or not. Oh well.
    # The code then removes the leading spaces because our intent is
    # to put this above a generated function to be valid roxygen
    # style comments
    values <- capture.output(print(fun))
    roxy_ids <- grepl("^[[:space:]]*#\'", values)

    if(!any(roxy_ids)){
        if(error){
            stop("This function doesn't have any detectable docstring")
        }else{
            return(NA)
        }

    }

    roxy_strings <- values[roxy_ids]
    roxy_strings <- gsub("^[[:space:]]*", "", roxy_strings)

    blanks <- grepl("^[[:space:]]*#\'[[:space:]]*$", values)
    keywords <- grepl("^[[:space:]]*#\'[[:space:]]*@", values)

    # If there are any blanks or keywords then leave it be.
    # otherwise stick the default title at the beginning
    if(!any(blanks) & !any(keywords)){
        roxy_strings <- c(paste("#'", default_title), "#' ", roxy_strings)
    }


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
    # fun_name <- function(x, y, ...)
    # NULL
    #
    # So let's add the function definition back in
    funargs[1] <- paste(fun_name, "<-", funargs[1])

    # Combine our extracted roxygen and the function definition
    roxy_text <- paste(c(roxy, funargs), collapse = "\n")
    return(roxy_text)
}

has_docstring <- function(fun, fun_name = as.character(substitute(fun))){
    out <- docstring_to_roxygen(fun, fun_name, error = FALSE)
    return(!is.na(out))
}


#' Display a docstring
#'
#' Display a docstring using R's built in help file viewer.
#'
#' @param fun The function that has the docstring you would like to display
#' @param fun_name The name of the function.
#' @param rstudio_pane logical. If running in RStudio do you want the help
#' to show in the help pane? This defaults to TRUE but can be explicitly set
#' using options("docstring_rstudio_help_pane" = TRUE) or
#' options("docstring_rstudio_help_pane" = FALSE)
#' @param default_title The title you would like to display if no title is detected
#' in the docstring itself. NOT YET IMPLEMENTED
#'
#' @importFrom roxygen2 roxygenize
#' @importFrom utils capture.output
#' @importFrom utils package.skeleton
#' @importFrom utils browseURL
#' @aliases ?
#'
#' @export
docstring <- function(fun, fun_name = as.character(substitute(fun)),
                      rstudio_pane = getOption("docstring_rstudio_help_pane"),
                      default_title = "Title not detected"){



    # Extract the roxygen style comments from the function's code
    # gives error if no docstring detected
    roxy_text <- docstring_to_roxygen(fun, fun_name = fun_name, default_title = default_title)

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

    # Create a fake environment to pass to package.skeleton
    # I don't really want it picking up the global environment
    # and there is more than what we need (and possible a name conflict)
    # within this environment so if we create a new environment we control
    # what gets created using package.skeleton.
    j <- new.env(parent = emptyenv())
    j$a <- 0
    suppressMessages(package.skeleton(name = package_name,
                                      path = temp_dir,
                                      environment = j)
                     )

    #on.exit(unlink(package_dir, recursive = TRUE)) # created w/ package.skeleton


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

    rstudio_pane <- ifelse(is.null(rstudio_pane), TRUE, rstudio_pane)

    # Require the user to be running Rstudio AND the option to be true
    isRStudio <- (Sys.getenv("RSTUDIO") == "1") && rstudio_pane

    if(isRStudio){
        rstudioapi::previewRd(generated_Rd_file)
        # Workaround since the file doesn't get displayed if we don't give
        # Rstudio time to do it's thing before the directory get's deleted.
        #Sys.sleep(1)
    }else{
        # Only supporting html for the time being apparently
        html_to_display <- tools::Rd2HTML(generated_Rd_file, tempfile(fileext = ".html"))
        browseURL(html_to_display)
    }


    return(invisible())
}

#' @export
`?` <- function (e1, e2)
{
    call <- match.call()

    original <- function() {
        # call the original ? function
        call[[1]] <- quote(utils::`?`)
        return(eval(call, parent.frame(2)))
    }

    # We don't handle requests with type
    if (!missing(e2)) {
        return(original())
    }

    # We only handle function calls where the object
    # exists in the global environment AND has a docstring.
    # otherwise pass it on...


    topicExpr1 <- substitute(e1)
    fun_name <- as.character(topicExpr1)

    # This is basically just checking if the object is defined
    fun <- get0(fun_name, .GlobalEnv, inherits=FALSE)
    if(!is.null(fun) && has_docstring(fun, fun_name)){
        docstring(fun = fun, fun_name = fun_name)
        return(invisible(NULL))
    }

    # All else failed - use original help function
    return(original())

}
