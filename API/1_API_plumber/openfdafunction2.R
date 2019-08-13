library(plumber)
p <- plumber::plumb(file = "plumber.R")
rstudioapi::viewer("http://ec2-3-17-14-3.us-east-2.compute.amazonaws.com:8000/__swagger__/")
p$run(port = 8000, host  = "0.0.0.0")

# http://ec2-3-17-14-3.us-east-2.compute.amazonaws.com/rstudio/s/7d2ab2b2579269af52609/p/3eb4e37b/outcomes?drug=FUROSEMIDE


