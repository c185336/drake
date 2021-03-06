% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read.R
\name{read_plan}
\alias{read_plan}
\title{Function \code{read_plan}}
\usage{
read_plan(path = getwd(), search = TRUE, cache = NULL)
}
\arguments{
\item{path}{Root directory of the drake project,
or if \code{search} is \code{TRUE}, either the
project root or a subdirectory of the project.}

\item{search}{logical. If \code{TRUE}, search parent directories
to find the nearest drake cache. Otherwise, look in the
current working directory only.}

\item{cache}{optional drake cache. See code{\link{new_cache}()}.
If \code{cache} is supplied,
the \code{path} and \code{search} arguments are ignored.}
}
\value{
a workflow plan data frame
}
\description{
Read the workflow plan
from your last attempted call to \code{\link{make}()}.
}
\examples{
\dontrun{
load_basic_example()
make(my_plan)
read_plan()
}
}
\seealso{
\code{\link{read_config}}
}
