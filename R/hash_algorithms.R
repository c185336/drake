#' @title Function available_hash_algos
#' @export
#' @description List the available hash algorithms.
#' @examples
#' available_hash_algos()
available_hash_algos <- function(){
  eval(formals(digest::digest)$algo)
}

#' @title Function long_hash
#' @export
#' @seealso \code{\link{default_short_hash_algo}},
#' \code{\link{default_long_hash_algo}}
#' @description Get the long hash algorithm of a drake cache.
#' @details See \code{?\link{default_long_hash_algo}()}
#' @param cache drake cache
#' @examples
#' \dontrun{
#' load_basic_example()
#' config <- make(my_plan, return_config = TRUE)
#' cache <- config$cache
#' long_hash(cache)
#' }
long_hash <- function(cache){
  if (!("long_hash_algo" %in% cache$list(namespace = "config"))){
    return(NULL)
  }
  cache$get("long_hash_algo", namespace = "config")
}

#' @title Function short_hash
#' @export
#' @seealso \code{\link{default_short_hash_algo}},
#' \code{\link{default_long_hash_algo}}
#' @description Get the short hash algorithm of a drake cache.
#' @details See \code{?\link{default_long_hash_algo}()}
#' @param cache drake cache
#' @examples
#' \dontrun{
#' load_basic_example()
#' config <- make(my_plan, return_config = TRUE)
#' cache <- config$cache
#' short_hash(cache)
#' }
short_hash <- function(cache){
  if (!("short_hash_algo" %in% cache$list(namespace = "config"))){
    return(NULL)
  }
  chosen_algo <- cache$get("short_hash_algo", namespace = "config")
  check_storr_short_hash(cache = cache, chosen_algo = chosen_algo)
  cache$get("short_hash_algo", namespace = "config")
}

#' @title Default short hash algorithm for \code{make()}
#' @export
#' @seealso \code{\link{make}}, \code{\link{available_hash_algos}}
#' @description Hashing is advanced. Most users
#' do not need to know about this function.
#' @details
#' The short algorithm must be among \code{\link{available_hash_algos}{}},
#' which is just the collection of algorithms available to the `algo`
#' argument in \code{digest::digest()}. \cr \cr
#'
#' If you express no preference for a hash, drake will use
#' the short hash for the existing project, or
#' \code{\link{default_short_hash_algo}()} for a new project.
#' If you do supply a hash algorithm, it will only apply to
#' fresh projects (see \code{\link{clean}(destroy = TRUE)}).
#' For a project that already exists, if you supply a hash algorithm,
#' drake will warn you and then ignore your choice, opting instead for
#' the hash algorithm already chosen for the project
#' in a previous \code{make()}. \cr \cr
#'
#' Drake uses both a short hash algorithm
#' and a long hash algorithm. The shorter hash has fewer characters,
#' and it is used to generate the names of internal cache files
#' and auxiliary files. The decision for short names is important
#' because Windows places restrictions on the length of file paths.
#' On the other hand, some internal hashes in drake are
#' never used as file names, and those hashes can use a longer hash
#' to avoid collisions.
#'
#' @param cache optional drake cache.
#' When you \code{\link{configure_cache}(cache)} without
#' supplying a short hash algorithm,
#' \code{default_short_hash_algo(cache)} is the short
#' hash algorithm that drake picks for you.
#' @examples
#' default_short_hash_algo()
default_short_hash_algo <- function(cache = NULL) {
  out <- "xxhash64"
  if (is.null(cache)){
    return(out)
  }
  if ("short_hash_algo" %in% cache$list(namespace = "config")){
    out <- cache$get(
      key = "short_hash_algo",
      namespace = "config"
    )
  }
  if ("storr" %in% class(cache)){
    out <- cache$driver$hash_algorithm
  }
  out
}

#' @title Default long hash algorithm for \code{make()}
#' @export
#' @seealso \code{\link{make}}, \code{\link{available_hash_algos}}
#' @description Hashing is advanced. Most users
#' do not need to know about this function.
#' @details
#' The long algorithm must be among \code{\link{available_hash_algos}{}},
#' which is just the collection of algorithms available to the `algo`
#' argument in \code{digest::digest()}. \cr \cr
#'
#' If you express no preference for a hash, drake will use
#' the long hash for the existing project, or
#' \code{\link{default_long_hash_algo}()} for a new project.
#' If you do supply a hash algorithm, it will only apply to
#' fresh projects (see \code{\link{clean}(destroy = TRUE)}).
#' For a project that already exists, if you supply a hash algorithm,
#' drake will warn you and then ignore your choice, opting instead for
#' the hash algorithm already chosen for the project
#' in a previous \code{make()}. \cr \cr
#'
#' Drake uses both a short hash algorithm
#' and a long hash algorithm. The shorter hash has fewer characters,
#' and it is used to generate the names of internal cache files
#' and auxiliary files. The decision for short names is important
#' because Windows places restrictions on the length of file paths.
#' On the other hand, some internal hashes in drake are
#' never used as file names, and those hashes can use a longer hash
#' to avoid collisions.
#'
#' @param cache optional drake cache.
#' When you \code{\link{configure_cache}(cache)} without
#' supplying a long hash algorithm,
#' \code{default_long_hash_algo(cache)} is the long
#' hash algorithm that drake picks for you.
#' @examples
#' default_long_hash_algo()
default_long_hash_algo <- function(cache = NULL) {
  out <- "sha256"
  if (is.null(cache)){
    return(out)
  }
  if ("long_hash_algo" %in% cache$list(namespace = "config")){
    out <- cache$get(
      key = "long_hash_algo",
      namespace = "config"
    )
  }
  out
}

check_storr_short_hash <- function(cache, chosen_algo){
  if ("storr" %in% class(cache)){
    true_algo <- cache$driver$hash_algorithm
    if (true_algo != chosen_algo){
      warning(
        "The storr-based cache actually uses ", true_algo,
        " for the short hash algorithm, but ", chosen_algo,
        " was also supplied. Reverting to ", true_algo, "."
      )
      cache$set(
        key = "short_hash_algo",
        value = true_algo,
        namespace = "config"
      )
    }
  }
}
