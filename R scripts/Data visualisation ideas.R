# Covid visualisation ideas ####

library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats', 'packcircles'))

github_repo_dir <- "~/Documents/Repositories/another_covid_repo"

ph_theme = function(){
  theme( 
    plot.title = element_text(colour = "#000000", face = "bold", size = 10),    
    plot.subtitle = element_text(colour = "#000000", size = 10),
    panel.grid.major.x = element_blank(), 
    panel.grid.minor.x = element_blank(),
    panel.background = element_rect(fill = "#FFFFFF"), 
    panel.grid.major.y = element_line(colour = "#E7E7E7", size = .3),
    panel.grid.minor.y = element_blank(), 
    strip.text = element_text(colour = "#000000", size = 10, face = "bold"), 
    strip.background = element_blank(), 
    axis.ticks = element_line(colour = "#dbdbdb"), 
    legend.position = "bottom", 
    legend.title = element_text(colour = "#000000", size = 9, face = "bold"), 
    legend.background = element_rect(fill = "#ffffff"), 
    legend.key = element_rect(fill = "#ffffff", colour = "#ffffff"), 
    legend.text = element_text(colour = "#000000", size = 9), 
    axis.text.y = element_text(colour = "#000000", size = 8), 
    axis.text.x = element_text(colour = "#000000", angle = 0, hjust = 1, vjust = .5, size = 8), 
    axis.title =  element_text(colour = "#000000", size = 9, face = "bold"),   
    axis.line = element_line(colour = "#dbdbdb")
  ) 
}

# Circular packing bubble plot 

# Create data
# data <- data.frame(group=paste("Group", letters[1:10]), value=sample(seq(1,100),10)) 
# 
# data <- data.frame(group=paste("Group", letters[1:10]), value= 1)
# 

# Generate the layout. This function returns a dataframe with one line per bubble. 
# It gives its center (x and y) and its radius, proportional of the value
# packing <- circleProgressiveLayout(data$value, 
#                                    sizetype='area') %>% 
#   mutate(radius = radius * .95)

# We can add these packing information to the initial data frame
# data <- cbind(data, packing)

# Check that radius is proportional to value. We don't want a linear relationship, since it is the AREA that must be proportionnal to the value
# plot(data$radius, data$value)

# The next step is to go from one center + a radius to the coordinates of a circle that
# is drawn by a multitude of straight lines.
# dat.gg <- circleLayoutVertices(packing, npoints=50)

# Make the plot
# ggplot() + 
#   geom_polygon(data = dat.gg, 
#                aes(x = x, 
#                    y = y, 
#                    group = id, 
#                    fill=as.factor(id)), 
#                colour = "black", 
#                alpha = 0.6) +
#   geom_text(data = data, aes(x, y, size=value, label = group)) +   # Add text in the center of each bubble + control its size
#   scale_size_continuous(range = c(1,4)) +
#   theme_void() + 
#   theme(legend.position="none") +
#   coord_equal()


# If you can figure out what this is doing, then you could probably use it for the circles in d3 rather than forcelayout.



# Density plot map

library(MASS)
library(ggplot2)
library(viridis)

#> Loading required package: viridisLite
# theme_set(theme_bw(base_size = 16))

# Get density of points in 2 dimensions.
# @param x A numeric vector.
# @param y A numeric vector.
# @param n Create a square n by n grid to compute density.
# @return The density within each square.
get_density <- function(x, y, ...) {
  dens <- MASS::kde2d(x, y, ...)
  ix <- findInterval(x, dens$x)
  iy <- findInterval(y, dens$y)
  ii <- cbind(ix, iy)
  return(dens$z[ii])
}

set.seed(1)
dat <- data.frame(
  x = c(
    rnorm(1e4, mean = 0, sd = 0.1),
    rnorm(1e3, mean = 0, sd = 0.1)
  ),
  y = c(
    rnorm(1e4, mean = 0, sd = 0.1),
    rnorm(1e3, mean = 0.1, sd = 0.2)
  )
)



