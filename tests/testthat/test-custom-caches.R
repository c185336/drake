cat(get_testing_scenario_name(), ": ", sep = "")
context("custom caches")

test_with_dir("cache_path finding", {
  x <- new_cache("x")
  expect_true(is.character(cache_path(x)))
  expect_null(cache_path(NULL))
  expect_null(cache_path(1234))
})

test_with_dir("fancy cache features, bad paths", {
  saveRDS(1, file = "exists")
  expect_error(x <- new_cache("exists"))
  expect_equal(type_of_cache("not_found"), NULL)
  expect_silent(tmp <- uncache(target = "targ", cache = NULL))
  expect_equal(get_storr_rds_cache("not_found"), NULL)
})

test_with_dir("null hashes", {
  x <- new_cache("x")
  x$del("short_hash_algo", namespace = "config")
  expect_null(short_hash(x))
  expect_false(is.null(long_hash(x)))
  y <- new_cache("y")
  y$del("long_hash_algo", namespace = "config")
  expect_false(is.null(short_hash(y)))
  expect_null(long_hash(y))
})

test_with_dir("First configure", {
  x <- new_cache()
  expect_equal(short_hash(x), default_short_hash_algo())
  expect_equal(long_hash(x), default_long_hash_algo())

  x <- configure_cache(
    cache = x,
    short_hash_algo = "crc32",
    long_hash_algo = "sha1"
  )
  expect_equal(short_hash(x), default_short_hash_algo())
  expect_equal(long_hash(x), default_long_hash_algo())

  expect_warning(
    x <- configure_cache(
      cache = x,
      short_hash_algo = "crc32",
      long_hash_algo = "sha1",
      overwrite_hash_algos = TRUE
    )
  )

  expect_equal(short_hash(x), default_short_hash_algo())
  expect_equal(long_hash(x), "sha1")

  expect_silent(
    x <- configure_cache(
      cache = x,
      long_hash_algo = "murmur32",
      overwrite_hash_algos = TRUE
    )
  )

  expect_equal(short_hash(x), default_short_hash_algo())
  expect_equal(long_hash(x), "murmur32")
})

test_with_dir("Pick the hashes", {
  x <- new_cache("new",
    short_hash_algo = "murmur32",
    long_hash_algo = "crc32"
  )
  expect_true(file.exists("new"))
  expect_equal(short_hash(x), "murmur32")
  expect_equal(long_hash(x), "crc32")
  x$del("long_hash_algo", namespace = "config")
  x <- configure_cache(x, long_hash_algo = "sha1")
  expect_equal(long_hash(x), "sha1")
  expect_error(configure_cache(x, long_hash_algo = "not found"))
  expect_error(configure_cache(x, short_hash_algo = "not found"))

  s <- short_hash(x)
  l <- long_hash(x)
  expect_silent(configure_cache(x, overwrite_hash_algos = TRUE))
  expect_equal(s, short_hash(x))
  expect_equal(l, long_hash(x))
})

test_with_dir("totally off the default cache", {
  saveRDS("stuff", file = "some_file")
  con <- dbug()
  unlink(default_cache_path(), recursive = TRUE)
  con$plan <- data.frame(target = "a", command = "c('some_file')")
  con$targets <- con$plan$target
  con$cache <- new_cache(
    path = "my_new_cache",
    short_hash_algo = "murmur32",
    long_hash_algo = "crc32"
  )
  make(
    con$plan,
    cache = con$cache,
    verbose = FALSE,
    parallelism = get_testing_scenario()$parallelism,
    jobs = get_testing_scenario()$jobs
  )
  expect_false(file.exists(default_cache_path()))
})

test_with_dir("use two differnt file system caches", {
  saveRDS("stuff", file = "some_file")
  targ <- "DRAKE_TEST_target"
  my_plan <- data.frame(target = targ, command = "my_function('some_file')")
  scenario <- get_testing_scenario()
  parallelism <- scenario$parallelism
  jobs <- scenario$jobs
  envir <- eval(parse(text = scenario$envir))
  if (targ %in% ls(envir)){
    rm(list = targ, envir = envir)
  }
  envir$my_function <- function(x){
    x
  }
  cache <- dbug()$cache

  con <- make(
    my_plan,
    cache = cache,
    envir = envir,
    verbose = FALSE,
    parallelism = parallelism,
    jobs = jobs,
    return_config = TRUE
  )

  o1 <- outdated(
    my_plan,
    envir = envir,
    verbose = FALSE,
    cache = cache
  )

  expect_equal(o1, character(0))
  expect_equal(
    short_hash(cache),
    con$short_hash_algo,
    cache$get("short_hash_algo", namespace = "config"),
    default_short_hash_algo()
  )
  expect_equal(
    long_hash(cache),
    con$long_hash_algo,
    cache$get("long_hash_algo", namespace = "config"),
    default_long_hash_algo()
  )
  expect_equal(
    short_hash(cache),
    cache$driver$hash_algorithm,
    default_short_hash_algo()
  )

  cache2 <- new_cache(
    path = "my_new_cache",
    short_hash_algo = "murmur32",
    long_hash_algo = "crc32"
  )
  o2 <- outdated(
    my_plan,
    envir = envir,
    verbose = FALSE,
    cache = cache2
  )
  con2 <- make(
    my_plan,
    cache = cache2,
    envir = envir,
    verbose = FALSE,
    parallelism = parallelism,
    jobs = jobs,
    return_config = TRUE
  )
  o3 <- outdated(
    my_plan,
    envir = envir,
    verbose = FALSE,
    cache = cache2
  )
  expect_equal(o2, targ)
  expect_equal(o3, character(0))
  expect_equal(
    short_hash(cache2),
    con2$short_hash_algo,
    cache2$get("short_hash_algo", namespace = "config"),
    "murmur32"
  )
  expect_equal(
    long_hash(cache2),
    con2$long_hash_algo,
    cache$get("long_hash_algo", namespace = "config"),
    "crc32"
  )
  expect_equal(
    short_hash(cache2),
    con2$cache$driver$hash_algorithm,
    "murmur32"
  )
  expect_true(grepl("my_new_cache", con2$cache$driver$path))
  expect_true(grepl("my_new_cache", cache_path(cache2)))
})
