#' @export
`?` <- function (e1, e2)
{
    call <- match.call()
    
    original <- function() {
        # Recreates the call but uses utils::`?`
        # So if we decide that docstring isn't the
        # way to go then we can still treat the input
        # like it would be treated if the docstring
        # package wasn't loaded.
        # TODO: Possibly try to play nice with devtools/sos?
        call[[1]] <- quote(utils::`?`)
        return(eval(call, parent.frame(2)))
    }
    
    # We don't handle requests with type
    if (!missing(e2)) {
        return(original())
    }
    
    
    topicExpr1 <- substitute(e1)
    fun_name <- as.character(topicExpr1)
    
    
    # We only handle function calls where the object
    # exists in the global environment AND has a docstring.
    # otherwise pass it on...
    # This is basically just checking if the object is defined
    # If not found, NULL
    # has_docstring(NULL) is FALSE
    fun <- get0(fun_name, .GlobalEnv, inherits=FALSE)
    if(has_docstring(fun, fun_name)){
        docstring(fun = fun, fun_name = fun_name)
        return(invisible(NULL))
    }
    
    # docstring isn't appropriate - use original help function
    return(original())
    
}
