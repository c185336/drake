% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/package.R
\name{\%>\%}
\alias{\%>\%}
\title{Pipe operator}
\usage{
lhs \%>\% rhs
}
\arguments{
\item{lhs}{left-hand side argument}

\item{rhs}{right-hand side argument}
}
\description{
Pipe operator from the \code{magrittr} package
}
\examples{
rnorm(2) \%>\%
  mean \%>\%
  c("third element")
}
