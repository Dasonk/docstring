#' Attempts to pull out the docstring and turn them into valid
#' roxygen style comments formated in a way that it should
#' be able to be written directly to a file
#'
#' @return  character - the roxygen strings if there is a docstring, error if not
#' @importFrom utils capture.output
#' @noRd
read_docstring <- function(fun, fun_name = as.character(substitute(fun)),
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
