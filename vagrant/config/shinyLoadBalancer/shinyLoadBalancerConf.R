# configuration file 
config <- list()
# name of the folder containing the load balancer app ? 
config$loadBalancerName = basename(
  normalizePath(
    dirname("app.R")
    )
  )
# Which directories / workers should be excluded ?
config$excludeWorkers = c(
  config$loadBalancerName,
  "sampleApp",
  "master",
  "dev",
  "archives",
  "w0",
  "home",
  "app"
  )
# additionnal path argument ex localhost:3838/<path>/worker
config$subdir = "app/"
