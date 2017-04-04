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
#' in the docstring itself.
#'
#' @usage docstring(fun, fun_name = as.character(substitute(fun)), 
#' rstudio_pane = getOption("docstring_rstudio_help_pane"),
#' default_title = "Title not detected")
#' 
#' ##?fun 
#' @importFrom roxygen2 roxygenize
#' @importFrom utils capture.output
#' @importFrom utils package.skeleton
#' @importFrom utils browseURL
#' @aliases ?
#' 
#' @examples 
#' \dontrun{
#' square <- function(x){
#'   #' Square a number
#'   #'
#'   #' Calculates the square of the input
#'   #' 
#'   #' @param x the input to be squared
#' 
#'   return(x^2)
#' }
#' 
#' docstring(square)
#' ?square
#' 
#' 
#' mypaste <- function(x, y = "!"){
#'   #' Paste two items
#'   #' 
#'   #' @description This function pastes two items
#'   #' together.  
#'   #'
#'   #' By using the description tag you'll notice that I
#'   #' can have multiple paragraphs in the description section
#'   #' 
#'   #' @param x character. The first item to paste
#'   #' @param y character. The second item to paste Defaults to "!" but
#'   #' "?" would be pretty great too
#'   #' @usage mypaste(x, y)
#'   #' @return The inputs pasted together as a character string.
#'   #' @details The inputs can be anything that can be input into
#'   #' the paste function.
#'   #' @note And here is a note. Isn't it nice?
#'   #' @section I Must Warn You:
#'   #' The reference provided is a good read.
#'   #' \subsection{Other warning}{
#'   #'   It is completely irrelevant to this function though.
#'   #' }
#'   #' 
#'   #' @references Tufte, E. R. (2001). The visual display of 
#'   #' quantitative information. Cheshire, Conn: Graphics Press.
#'   #' @examples
#'   #' mypaste(1, 3)
#'   #' mypaste("hey", "you")
#'   #' mypaste("single param")
#'   #' @export
#'   #' @importFrom base paste
#'   
#'   return(paste(x, y))
#' }
#'   
#' ?mypaste
#' }
#' 
#' @export
docstring <- function(fun, fun_name = as.character(substitute(fun)),
                      rstudio_pane = getOption("docstring_rstudio_help_pane"),
                      default_title = "Title not detected"){



    # Extract the roxygen style comments from the function's code.
    # Gives error if no docstring detected. The error will only
    # show up if running docstring directly. If using ? to access the docstring
    # has_docstring (which doesn't create and error) is used before 
    # calling docstring so we shouldn't get an error in that situation.
    roxy_text <- read_docstring(fun, fun_name = fun_name, default_title = default_title)

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

    # Cleaning up like this caused a race condition. RStudio help wasn't
    # showing up half the time. We aren't being perfect citizens by not
    # cleaning up but we do clean up from previous runs at the beginning
    # of the function so only one copy of crud will be on the system
    # at any given time.  Unless the temp directory changes. In which
    # case more can be on the system but oh well it's temp and will get
    # deleted at some point anyways.
    #on.exit(unlink(package_dir, recursive = TRUE)) # created w/ package.skeleton


    # package.skeleton doesn't create an R folder if there isn't any
    # code passed in
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
        return(invisible())
    }
    
    type <- getOption("help_type")
    if(is.null(type)){
        # Assuming text if it's null because I think that's the safest
        # to assume. It shouldn't cause any issues on terminals and in
        # a GUI environment it won't cause issues either. html on the
        # other hand can cause some issues if those capabilities aren't
        # present.
        type <- "text"
    }
    
    if(type == "html"){
        html_to_display <- tools::Rd2HTML(generated_Rd_file, tempfile(fileext = ".html"))
        browseURL(html_to_display)
    }else if(type == "text"){
        txt_to_display <- tools::Rd2txt(generated_Rd_file, tempfile(fileext = ".txt"))
        file.show(txt_to_display)
    }else{
        stop("Only help_type of html or text are supported in docstring")
    }


    return(invisible())
}

