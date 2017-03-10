# docstring

The docstring package is an R package that provides the ability to 
display something analagous to
Python's docstrings within R.  By allowing the user to document
their functions as comments at the beginning of their function
without requiring putting the function into a package we allow
more users to easily provide documentation for their functions.
The documentation can be viewed using an accessor function but
displays just like any other R help files.

The user will need to be familiar with roxygen style comments (via the roxygen2 package)
to fully utilize the package.  Eventually I want to detect basic comments and
allow the user to just use those as the documentation without requiring
the use of the roxygen keywords at least for simple cases.  Ideally this will
allow users not yet comfortable with package creation to still provide
documentation for their functions. If they use the roxygen style comments when it
is time to convert their work into a package all they will need to do is move
their pre-existing documentation outside of the function and they will be set.

## Examples

```r
library(docstring)

square <- function(x){

    #' Square a number
    #'
    #' Calculates the square of the input
    #'
    #' @param x the input to be squared

    return(x^2)
}

docstring(square)
```

![Square](docs/images/square.png)



## Installation

The package is not yet on CRAN but is available to download using devtools.

You can also download the dev version via [zip ball](https://github.com/dasonk/docstring/zipball/master) or [tar ball](https://github.com/dasonk/docstring/tarball/master), decompress and run `R CMD INSTALL` on it, or use the **devtools** package to install the development version:

```r
## Make sure your current packages are up to date
update.packages()
## devtools is required
library(devtools)
install_github("dasonk/docstring")
```

Note: Windows users need [Rtools](http://www.murdoch-sutherland.com/Rtools/) and [devtools](http://CRAN.R-project.org/package=devtools) to install this way.


## Contact

You are welcome to:
* submit suggestions and bug-reports at: <https://github.com/dasonk/docstring/issues>
* send a pull request on: <https://github.com/dasonk/docstring/>


