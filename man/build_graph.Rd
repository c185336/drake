% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/graph.R
\name{build_graph}
\alias{build_graph}
\title{Function \code{build_graph}}
\usage{
build_graph(plan, targets = drake::possible_targets(plan),
  envir = parent.frame(), verbose = TRUE, cache = NULL)
}
\arguments{
\item{plan}{workflow plan data frame, same as for function
\code{\link{make}()}.}

\item{targets}{names of targets to bulid, same as for function
\code{\link{make}()}.}

\item{envir}{environment to import from, same as for function
\code{\link{make}()}.}

\item{verbose}{logical, whether to output messages to the console.}

\item{cache}{optional drake cache, as from \code{\link{new_cache}()}.
The cache is used to check for back-compatibility with projects
created with drake 4.2.0 or earlier. In these legacy projects,
packages will not be tracked as dependencies. In projects created with
a version of drake later than 4.2.0, packages are formally tracked as
imports.}
}
\description{
Make a graph of the dependency structure of your workflow.
}
\details{
This function returns an igraph object representing how
the targets in your workflow depend on each other.
(\code{help(package = "igraph")}). To plot the graph, call
to \code{\link{plot.igraph}()} on your graph, or just use
\code{\link{plot_graph}()} from the start.
}
\examples{
\dontrun{
load_basic_example()
g <- build_graph(my_plan)
class(g)
}
}
\seealso{
\code{\link{plot_graph}}
}
