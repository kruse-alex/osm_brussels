# pkg
require(stringr)
require(dplyr)

# setwd
# your WD

# import data
mydata = read.csv("brussels_fake.csv", header = T, sep = ";")

# clean station names
mydata$name = substring(mydata$name, 7)
mydata$name.1 = substring(mydata$name.1, 7)

# clean coords
mydata$new = str_split_fixed(mydata$position.1, ", ", 2)
mydata$position.1 = gsub(".*\\,","", mydata$position.1)
mydata$new2 = str_split_fixed(mydata$position, ", ", 2)
mydata$position = gsub(".*\\,","", mydata$position)

# set column names and data type
mydata = select(mydata, name, position, new2, name.1, position.1, new, count)
colnames(mydata) = c("from","from_lon","from_lat","to","to_lon","to_lat","count")
mydata$from_lon = as.numeric(mydata$from_lon)
mydata$to_lon = as.numeric(mydata$to_lon)
mydata$from_lat = as.numeric(mydata$from_lat)
mydata$to_lat = as.numeric(mydata$to_lat)

# change comma to dot
mydata$to_lat = gsub('^(.{2})(.*)$', '\\1.\\2', mydata$to_lat)
mydata$from_lat = gsub('^(.{2})(.*)$', '\\1.\\2', mydata$from_lat)
mydata$to_lon = gsub('^(.{1})(.*)$', '\\1.\\2', mydata$to_lon)
mydata$from_lon = gsub('^(.{1})(.*)$', '\\1.\\2', mydata$from_lon)

# sumulate some count data
mydata$count = sample.int(1000, size = 216, replace = TRUE)

# write data frame to csv
write.table(mydata, "bikerides.csv", row.names = F, sep = ";")
