#' O2TimeSeries FUNCTION: Return modeled oxygen time series from median GPP,
#' ER estimates. Internal function.
#'
#' ARGUMENTS:
#'    GPP
#'    ER
#     O2data    Dataframe of cleaned raw two station data (ex. "TS_S1S2")
#     Kmean
#     z
#     tt
#     upName        Character name of upstream station (ex. "S1")
#     downName      Character name of downstream station (ex. "S2")
O2TimeSeries <- function(GPP, ER, O2data, Kmean, z, tt, upName, downName) {
  # Ungroup O2data
  O2data <- O2data %>% ungroup()

  #number of 5 min readings bewteen up and down probe corresponding
  # to travel time tt
  lag <- as.numeric(round(tt/0.0104166667))

  # trim the ends of the oxy and temp data by the lag so that oxydown[1]
  # is the value that is the travel time later than oxy up. The below
  # calls are designed to work with our data structure.

  # Seperate data into upstream and downstream sections
  updata <- O2data[O2data$`river station` == upName,]
  downdata <- O2data[O2data$`river station` == downName,]

  tempup <- updata$temp[1:as.numeric(length(updata$temp)-lag)] # trim the end by the lag
  tempdown <- downdata$temp[(1+lag):length(downdata$temp)]

  oxyup <- updata$oxy[1:as.numeric(length(updata$temp)-lag)]
  # define osat
  osat <- updata$DO.sat[1:as.numeric(length(updata$temp)-lag)]
  oxydown <- downdata$oxy[(1+lag):length(downdata$temp)]

  timeup <- updata$dtime[1:(length(updata$temp)-lag)]
  timedown <- downdata$dtime[(1+lag):length(downdata$temp)]

  light <- downdata$light

  # Initialize an empty vector
  modeledO2 <- numeric(length(oxyup))
  # Calculate metabolism at each timestep
  for (i in 1:length(oxyup)) {
    modeledO2[i] <- (oxyup[i] + ((GPP/z)*(sum(light[i:(i+lag)]) / sum(light))) +
                       ER*tt/z +
                       (Kcor(tempup[i],Kmean))*tt*(osat[i] -
                                                     oxyup[i] +
                                                     osat[i])/2) /
      (1 + Kcor(tempup[i],Kmean)*tt/2)
  }

  # Convert time from chron to posixct
  timeup <- as.POSIXlt(timeup)
  timedown <- as.POSIXlt(timedown)

  oxymodel <- data.frame(timeup, timedown, oxydown, oxyup, modeledO2)
  return(oxymodel)
}