cat(get_testing_scenario_name(), ": ", sep = "")
context("arbitrary cache")

test_with_dir("storr_environment is a cache type", {
  expect_true("storr_environment" %in% cache_types())
  expect_error(tmp <- new_cache(type = "not found"))
  expect_error(
    x <- new_cache(type = "storr_environment",
      short_hash_algo = "murmur32",
      long_hash_algo = "not found"
    )
  )
  file.create(default_cache_path())
  x <- new_cache(type = "storr_environment",
    short_hash_algo = "murmur32",
    long_hash_algo = "sha1"
  )
  unlink(default_cache_path(), recursive = TRUE)
  expect_false(file.exists(default_cache_path()))
  expect_equal(short_hash(x), "murmur32")
  expect_equal(long_hash(x), "sha1")
  x <- new_cache(type = "storr_environment")
  expect_false(file.exists(default_cache_path()))
  expect_equal(short_hash(x), default_short_hash_algo())
  expect_equal(long_hash(x), default_long_hash_algo())
  expect_error(session(cache = x))
  pln <- plan(y = 1)
  make(pln, cache = x, verbose = FALSE)
  expect_equal(cached(cache = x), "y")
  expect_false(file.exists(default_cache_path()))
  expect_equal(outdated(pln, cache = x, verbose = FALSE), character(0))
  expect_false(file.exists(default_cache_path()))
})

test_with_dir("possibly superfluous function get_storr_environment_cache", {
  tmp <- get_storr_environment_cache(
    short_hash_algo = "md5",
    long_hash_algo = "md5"
  )
  expect_true("storr" %in% class(tmp))
})

test_with_dir("can get_cache() a storr_environment", {
  e <- new.env()
  y <- new_cache(type = "storr_environment", envir = e,
    short_hash_algo = "crc32"
  )
  expect_equal(e$hash_algorithm, "crc32")
})

test_with_dir("arbitrary storr in-memory cache", {
  expect_false(file.exists(default_cache_path()))
  parallelism <- default_parallelism()
  jobs <- 1
  envir <- eval(parse(text = get_testing_scenario()$envir))
  cache <- storr::storr_environment(hash_algorithm = "murmur32")
  load_basic_example(envir = envir)
  my_plan <- envir$my_plan
  con <- make(
    my_plan,
    envir = envir,
    cache = cache,
    parallelism = parallelism,
    jobs = jobs,
    verbose = FALSE,
    return_config = TRUE
  )
  envir$reg2 <- function(d){
    d$x3 <- d$x ^ 3
    lm(y ~ x3, data = d)
  }
  expect_false(file.exists(default_cache_path()))
  expect_equal(short_hash(con$cache), "murmur32")
  expect_equal(long_hash(con$cache), default_long_hash_algo())

  x <- predict_runtime(
    plan = my_plan, envir = envir, cache = cache, verbose = FALSE
  )
  y <- rate_limiting_times(
    plan = my_plan, envir = envir, cache = cache, from_scratch = TRUE,
    verbose = FALSE
  )
  expect_true(length(x) > 0)
  expect_true(nrow(y) > 0)

  expect_equal(cached(), character(0))
  targets <- my_plan$target
  expect_true(all(targets %in% cached(cache = cache)))
  expect_false(file.exists(default_cache_path()))

  expect_error(session())
  expect_true(is.list(session(cache = cache)))
  expect_false(file.exists(default_cache_path()))

  expect_equal(length(imported()), 0)
  expect_true(length(imported(cache = cache)) > 0)
  expect_false(file.exists(default_cache_path()))

  expect_equal(length(built()), 0)
  expect_true(length(built(cache = cache)) > 0)
  expect_false(file.exists(default_cache_path()))

  expect_equal(nrow(build_times()), 0)
  expect_true(nrow(build_times(cache = cache)) > 0)
  expect_false(file.exists(default_cache_path()))

  o1 <- outdated(my_plan, envir = envir, verbose = FALSE)
  unlink(default_cache_path(), recursive = TRUE)
  o2 <- outdated(my_plan, jobs = 2, cache = cache,
    envir = envir, verbose = FALSE)
  expect_true(length(o1) > length(o2))
  expect_false(file.exists(default_cache_path()))

  p <- plot_graph(my_plan, envir = envir,
    cache = cache, verbose = FALSE, file = "graph.html")
  expect_false(file.exists(default_cache_path()))

  m1 <- max_useful_jobs(my_plan, envir = envir, verbose = F)
  unlink(default_cache_path(), recursive = TRUE)
  m2 <- max_useful_jobs(my_plan, envir = envir, verbose = F, cache = cache)
  expect_equal(m1, 8)
  expect_equal(m2, 4)
  expect_false(file.exists(default_cache_path()))

  p1 <- progress()
  unlink(default_cache_path(), recursive = TRUE)
  p2 <- progress(cache = cache)
  expect_true(length(p2) > length(p1))
  expect_false(file.exists(default_cache_path()))

  expect_error(read_config())
  expect_true(is.list(read_config(cache = cache)))
  expect_false(file.exists(default_cache_path()))

  expect_error(read_graph())
  expect_equal(class(read_graph(cache = cache)), "igraph")
  expect_false(file.exists(default_cache_path()))

  expect_error(read_plan())
  expect_true(is.data.frame(read_plan(cache = cache)))
  expect_false(file.exists(default_cache_path()))

  expect_error(readd(small))
  expect_true(is.data.frame(readd(small, cache = cache)))
  expect_false(file.exists(default_cache_path()))

  expect_error(loadd(large))
  expect_error(nrow(large))
  expect_silent(loadd(large, cache = cache))
  expect_true(nrow(large) > 0)
  rm(large)
  expect_false(file.exists(default_cache_path()))
})
