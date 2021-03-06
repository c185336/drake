cat(get_testing_scenario_name(), ": ", sep = "")
context("edge-cases")

test_with_dir("misbehavior with packages", {
  x <- data.frame(target = "package:asdflkjlskdjioelkjdi", command = 1)
  expect_warning(tmp <- sanitize_plan(x))
  expect_warning(tmp <- sanitize_targets(plan = x, targets = x$target))
  config <- list(installed_packages = c())
  pkg <- "skldjfie"
  hov <- package_hover_text(pkg, config = config)
  expect_equal(hov, pkg)
})

test_with_dir("graph does not fail if input file is binary", {
  x <- plan(y = readRDS("input.rds"))
  saveRDS(as.list(mtcars), "input.rds")
  expect_silent(out <- plot_graph(x, verbose = FALSE))
  unlink("input.rds", force = TRUE)
})

test_with_dir("illegal hashes", {
  x <- plan(a = 1)
  expect_error(make(x, short_hash_algo = "no_such_algo_aslkdjfoiewlk"))
  expect_error(make(x, long_hash_algo = "no_such_algo_aslkdjfoiewlk"))
})

test_with_dir("different graphical arrangements for Makefile parallelism", {
  e <- new.env()
  x <- plan(a = 1, b = f(2))
  e$f <- function(x) x
  con <- config(x, envir = e, verbose = FALSE)
  expect_equal(1, max_useful_jobs(x, envir = e, config = con,
    parallelism = "mclapply", jobs = 1))
  expect_equal(1, max_useful_jobs(x, envir = e, config = con,
    parallelism = "parLapply", jobs = 1))
  con$parallelism <- "Makefile"
  expect_equal(2, max_useful_jobs(x, envir = e, config = con,
    parallelism = "Makefile", jobs = 1))
})

test_with_dir("Vectorized nested functions work", {
  e <- new.env(parent = globalenv())
  eval(parse(text = "f <- Vectorize(function(x) g(x), \"x\")"),
    envir = e)
  eval(parse(text = "g <- function(x) x + y"), envir = e)
  e$y <- 7
  config <- dbug()
  config$envir <- e
  config$plan <- plan(a = f(1:10))
  config$targets <- "a"
  expect_equal(deps(e$f), "g")
  expect_equal(deps(e$g), "y")

  testrun(config)
  if ("a" %in% ls(config$envir)){
    rm(a, envir = config$envir)
  }
  expect_equal(readd(a), 8:17)
  k <- readd(f)
  expect_equal(k(2:5), 9:12)
  expect_equal(character(0), outdated(config$plan, envir = config$envir,
    verbose = FALSE))
  config$envir$y <- 8
  expect_equal("a", outdated(config$plan, envir = config$envir,
    verbose = FALSE))

  # Target "a" should react.
  testrun(config)
  expect_equal(character(0), outdated(config$plan, envir = config$envir,
    verbose = FALSE))
  expect_equal(readd(a), 9:18)

  # Change a vectorized function and see target "a" react.
  eval(parse(text = "f <- Vectorize(function(x){g(x) + 3}, \"x\")"),
    envir = e)
  testrun(config)
  expect_equal(justbuilt(config), "a")
  expect_equal(readd(a), 12:21)
})

test_with_dir("stringsAsFactors can be TRUE", {
  f <- function(x) {
    return(x)
  }
  myplan <- data.frame(target = "a", command = "f(\"helloworld\")",
    stringsAsFactors = TRUE)
  expect_true(is.factor(myplan$target))
  expect_true(is.factor(myplan$command))
  make(myplan, verbose = FALSE)
  expect_equal(readd(a), "helloworld")
})

test_with_dir("circular non-DAG workflows quit in error", {
  p <- plan(a = b, b = c, c = a)
  expect_error(tmp <- capture.output(check(p)))
  expect_error(make(p, verbose = FALSE))
})

# Target/import conflicts are unpredictable. A warning should
# be enough.
test_with_dir("target conflicts with current import or another target", {
  config <- dbug()
  config$plan <- rbind(config$plan, data.frame(target = "f",
    command = "1+1"))
  expect_silent(tmp <- capture.output(check(plan = config$plan,
    envir = config$envir)))
  config$plan$target <- "repeated"
  expect_error(check(plan = config$plan))
})

test_with_dir("target conflicts with previous import", {
  config <- dbug()
  testrun(config)
  config$plan$command[2] <- "g(1+1)"
  config$plan <- rbind(config$plan, data.frame(target = "f",
    command = "1+1"))
  config$targets <- config$plan$target
  testrun(config)
  expect_equal(justbuilt(config), sort(c("'intermediatefile.rds'",
    "combined", "f", "final", "yourinput")))
})

test_with_dir("can use semicolons and multi-line commands", {
  plan <- plan(list = c(x = "a<-1; a", y = "b<-2\nb"))
  make(plan, verbose = FALSE)
  expect_false(any(c("a", "b") %in% ls()))
  expect_true(all(cached(x, y, search = FALSE)))
  expect_equal(cached(search = FALSE), c("x", "y"))
})

test_with_dir("true targets can be functions", {
  generator <- function() return(function(x) {
    x + 1
  })
  plan <- plan(myfunction = generator(), output = myfunction(1))
  config <- make(plan, verbose = FALSE, return_config = TRUE)
  expect_equal(readd(output), 2)
  expect_true(is.list(config$cache$get("myfunction")))
  myfunction <- readd(myfunction)
  expect_equal(myfunction(4), 5)
})

test_with_dir("error when file target names do not match actual filenames", {
  x <- plan(y = 1, file_targets = TRUE)
  expect_warning(expect_error(make(x, verbose = FALSE)))
})

test_with_dir("stress test hashing decisions", {
  file <- "input.rds"
  expect_true(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 0, size_cutoff = Inf))
  expect_true(should_rehash_file(
    file = file, new_mtime = 1, old_mtime = 0, size_cutoff = Inf))
  expect_true(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 1, size_cutoff = Inf))
  expect_true(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 0, size_cutoff = -1))
  expect_true(should_rehash_file(
    file = file, new_mtime = 1, old_mtime = 0, size_cutoff = -1))
  expect_true(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 1, size_cutoff = -1))
  saveRDS(1, file = file)
  expect_true(file.exists(file))
  expect_true(should_rehash_file(
    file = file, new_mtime = 1, old_mtime = 0, size_cutoff = Inf))
  expect_true(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 1, size_cutoff = Inf))
  expect_true(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 0, size_cutoff = Inf))
  expect_true(should_rehash_file(
    file = file, new_mtime = 1, old_mtime = 0, size_cutoff = -1))
  expect_false(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 1, size_cutoff = -1))
  expect_false(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 0, size_cutoff = -1))
  unlink(file, force = TRUE)
})

test_with_dir("parallelism not found for testrun()", {
  config <- list(parallelism = "not found")
  expect_error(testrun(config))
})
