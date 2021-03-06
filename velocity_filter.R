require(data.table)
# velocity filter removes a location according to velocity
# details:
      # it removes a location whenever both the velocity from the previous point to it (v_in) and the velocity from it to the next point (v_out) are greater than  spdThreshold
      # it repeats the filtering with different step size:
            # step=0 means that the velocity is calculated between nearest neighbors (in time)
            # step=1 means that the velocity is calculated between second nearest neighbors
            # the input variable "steps" determines up to which neighbor to check velocity (default=1)
            # thus it can filter locations in case that a set of points up to size "steps" was drifted away
# input variable "data" is a data.frame with locations saved with column names x,y, and time
# returns the data.frame without the filtered locations
velocity_filter <- function (data,spdThreshold=15, x = "X", y = "Y", time = "TIME", steps=1) 
{
for(i in 1:steps){
  spd <- matl_get_speed(data,x=x,y=y,time=time,type = "in",step = i)*1000
  KEEP <- (spd<spdThreshold)|(shift(spd,-i)<spdThreshold)
  KEEP[is.na(KEEP)] <- TRUE  
  data<-data[which(KEEP),]
  print(sprintf("step %i removed %i locations",i,sum(!KEEP)))
}
return(data)  
}

# velocity filter removes a location  according to distance
# details:
      # it removes a location whenever both the distance from the previous point to it and the distance from it to the next point are greater than distThreshold
      # it repeats the filtering with different step size:
          # step=0 means that the distance is calculated between nearest neighbors (in time)
          # step=1 means that the distance is calculated between second nearest neighbors
          # the input variable "steps" determines up to which neighbor to check distance (default=1)
          # thus it can filter locations in case that a set of points up to size "steps" was drifted away
# input variable "data" is a data.frame with locations saved with column names x,y, and time
# returns the data.frame without the filtered locations
distance_filter <- function (data,distThreshold=15*8, x = "X", y = "Y", time = "TIME", type = "in", steps=1) 
{
  for(i in 1:steps){
    dst <- matl_simple_dist(data,x=x,y=y,step = i)
    KEEP <- (dst<distThreshold)|(shift(dst,i)<distThreshold)
    KEEP[is.na(KEEP)] <- TRUE  
    data<-data[which(KEEP),]
    print(sprintf("step %i removed %i locations",i,sum(!KEEP)))
  }
  return(data)  
}

# calculates a distance between subsequent points (or the next "step" point)
# used within the filters
matl_simple_dist <- function (data, x = "x", y = "y",step=1) 
{
  assertthat::assert_that(is.data.frame(data), is.character(x), 
                          is.character(y), msg = "simpleDist: some data assumptions are not met")
  if (nrow(data) > 1) {
    x1 <- data[[x]][seq_len(nrow(data) - step)]
    x2 <- data[[x]][(1+step):nrow(data)]
    y1 <- data[[y]][seq_len(nrow(data) - step)]
    y2 <- data[[y]][(1+step):nrow(data)]
    dist <- c(sqrt((x1 - x2)^2 + (y1 - y2)^2))
  }
  else {
    dist <- NA_real_
  }
  return(dist)
}
# calculates a speed between subsequent points (or the next "step" point)
# used within the filters
matl_get_speed <- function (data, x = "x", y = "y", time = "time", type = "in", step=1) 
{
  # atlastools::atl_check_data(data, names_expected = c(x, y, time))
  data.table::setorderv(data, time)
  distance <- matl_simple_dist(data, x, y,step)
  # distance <- distance[(step+1):length(distance)]
  dtime <- data[[time]][(step+1):nrow(data)]-data[[time]][1:(nrow(data)-step)]
  # time <- c(NA, diff(data[[time]]))
  speed <- distance/dtime
  if (type == "in") {
    speed <- c(rep(NA,step),speed)
  }
  else if (type == "out") {
    speed <-c(speed,rep(NA,step))
  }
  return(speed)
}
