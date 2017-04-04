has_docstring <- function(fun, fun_name = as.character(substitute(fun))){
    out <- read_docstring(fun, fun_name, error = FALSE)
    return(!is.na(out))
}