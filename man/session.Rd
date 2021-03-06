% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/progress.R
\name{session}
\alias{session}
\title{Function \code{session}}
\usage{
session(path = getwd(), search = TRUE, cache = NULL)
}
\arguments{
\item{path}{Root directory of the drake project,
or if \code{search} is \code{TRUE}, either the
project root or a subdirectory of the project.}

\item{search}{If \code{TRUE}, search parent directories
to find the nearest drake cache. Otherwise, look in the
current working directory only.}

\item{cache}{optional drake cache. See code{\link{new_cache}()}.
If \code{cache} is supplied,
the \code{path} and \code{search} arguments are ignored.}
}
\value{
\code{\link{sessionInfo}()} of the last
call to \code{\link{make}()}
}
\description{
Load the \code{\link{sessionInfo}()}
of the last call to \code{\link{make}()}.
}
\examples{
\dontrun{
load_basic_example()
make(my_plan)
session()
}
}
\seealso{
\code{\link{built}}, \code{\link{imported}},
\code{\link{readd}}, \code{\link{plan}}, \code{\link{make}}
}
