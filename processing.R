####################################################################################################################
# IMPORT AND PROCESS DATA
####################################################################################################################

# load packages
x = c("dplyr","data.table","sp","stplanr","leaflet","RColorBrewer")
lapply(x, require, character.only = T)

# setwd
setwd("C:/Users/akruse/Documents/Projekte_Weitere/brussels")

# import bike rentals (I've created a fake dataset via https://opendata.brussels.be/explore/dataset/villo-stations-availability-in-real-time/)
mydata = read.csv("bikerides.csv", header = T, sep = ";")
mydata1 = mydata[c(2:3,7:8)]
colnames(mydata1) = c("lon","lat","count","id")
mydata2 = mydata[c(5:8)]
colnames(mydata2) = c("lon","lat","count","id")
mydata = rbind(mydata1, mydata2)

# import rental stations
stations = read.csv("bikerides.csv", header = T, sep = ";")
stations1 = stations[,1:3]
colnames(stations1) = c("name","lon","lat")
stations2 = stations[,4:6]
colnames(stations2) = c("name","lon","lat")
stations = rbind(stations1, stations2)
stations = stations[!duplicated(stations), ]

####################################################################################################################
# TRANSFORM DATA INTO LINE NETWORK
####################################################################################################################

# transform to listed lines
dt = as.data.table(mydata)
lst_lines = lapply(unique(dt$id), function(x){
  Lines(Line(dt[id == x, .(lon, lat)]), ID = x)
})

# plot line as example
plot(lst_lines[[1]]@Lines[[1]]@coords, type = "l")

# transform to SPDF
spl_lst = SpatialLines(lst_lines)
spl_df = SpatialLinesDataFrame(spl_lst, data.frame(mydata$count))

####################################################################################################################
# TRANSFORM LINES INTO ROUTES
####################################################################################################################

# check for cs key (can be saved in .Renviron)
Sys.getenv("CYCLESTREET")

# get routes from cyclestreet API
spl_df = line2route(spl_df, "route_cyclestreet", plan = "fastest")

# add ride count for each route
spl_df@data$count = mydata[1:216,]$count

# aggregate ride counts on overlapping routes
spl_df = overline(spl_df, attrib = "count", fun = sum)

####################################################################################################################
# CREATE LEAFLET MAP
####################################################################################################################

# create coloring function
qpal = colorQuantile(rev(brewer.pal(5, "YlGnBu")), NULL)

# create leaflet map
leaflet(spl_df) %>%
  addTiles('http://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
           attribution='Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>') %>%
  addPolylines(color = qpal(spl_df@data$count), opacity = 1, weight = 1.5, popup = paste("BikeCount:",spl_df@data$count)) %>%
  addCircleMarkers(lng = stations$lon, lat = stations$lat, popup = paste("Station:",stations$name),
                  fillOpacity = 100, color = "red", stroke = F, radius = 3) %>%
  addMarkers(lng = 4.357478, lat = 50.845509, popup = paste("We R here today!")) %>%
  addLegend(position = 'bottomleft',colors =  rev(brewer.pal(5, "YlGnBu")),labels = c("Very low","Low","Average","High","Very high"),title = 'Frequency')