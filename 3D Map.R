# Libraries and functions -------------------------------------------------
library(elevatr)
library(rayshader)
library(imager)
library(rgl)
library(raster)
library(plotKML)
library(dplyr)
library(magick)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("arcgis_map_api.R")
source("image_size.R")


# Convert lat and long to rayshader grid coordinates
xvec <- function(x){
  xmin <- elev_img@extent@xmin
  xmin_vec <- rep(xmin,length(gpx$lon))
  (x-xmin_vec[length(x)])/ res(elev_img)[1]
}
yvec <- function(x){
  ymin <- elev_img@extent@ymin
  ymin_vec <- rep(ymin,length(gpx$lat))
  (x-ymin_vec[length(x)])/ res(elev_img)[2]
}

# Retrieve route and elevation data -----------------------------------------
gpx.df <- readGPX("t120138373_grossvenediger_hike.gpx")
gpx <- gpx.df$tracks %>%
  unlist(recursive = FALSE) %>%
  as.data.frame()

# Convert column classes 
gpx[1:3] <- as.numeric(unlist(gpx[1:3]))
colnames(gpx) <- c("lon","lat","ele")

# Find Bounding Box
lat_min <- min(gpx$lat)*0.999 ; lat_max <- max(gpx$lat)*1.001
long_min <- min(gpx$lon)*0.999 ; long_max <- max(gpx$lon)*1.001

# Get elevation data of bounding box, borrowed from https://github.com/edeaster/Routes3D/blob/master/3D-map_gps_route.R
ex.df <- data.frame(x= c( long_min, long_max), 
                    y=c(lat_min,lat_max))
prj_dd <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
elev_img <- get_elev_raster(ex.df, prj = prj_dd, z = 12, clip = "bbox")
elev_tif <- raster::writeRaster(elev_img, "elevation.tif",overwrite= TRUE)
dim <- dim(elev_tif)
elev_matrix <- matrix(
  raster::extract(elev_img, raster::extent(elev_img), buffer = 1000), 
  nrow = ncol(elev_img), ncol = nrow(elev_img))
# Create Overlay
bbox <- list(
  p1 = list(long = long_max, lat = lat_min),
  p2 = list(long = long_min, lat = lat_max)
)

# Create overlay from satellite image ----------------------------------------------------

image_size <- define_image_size(bbox, 1200)
file <- get_arcgis_map_image(bbox, 
                             map_type = "World_Imagery",
                             width = image_size$width, 
                             height = image_size$height)

overlay_img <- png::readPNG(file)

# Create the 3D Map -------------------------------------------------------

# Calculate rayshader layers using elevation data
ambmat <- ambient_shade(elev_matrix, zscale = 8)
raymat <- ray_shade(elev_matrix, zscale = 8, lambert = TRUE)

# Create RGL object
rgl::clear3d()

elev_matrix %>% 
  sphere_shade(texture = "imhof4") %>% 
  add_overlay(., overlay = overlay_img, alphacolor = NULL,alphalayer = 0.9)  %>%
  add_shadow(raymat, max_darken = 0.5) %>%
  add_shadow(ambmat, max_darken = 0.5) %>%
  plot_3d(elev_matrix,zscale = 10, zoom = 0.5, fov = 70, theta = 80, phi = 25, windowsize = c(1850, 1040))

# Plot labels on the 3D Map
render_label(elev_matrix, x = xvec(gpx$lon[1]), y = yvec(gpx$lat[1]), z = 1200, zscale = 10, textsize = 20, linewidth = 4, text = "Start", freetype = FALSE)
render_label(elev_matrix, x = xvec(12.495658), y = yvec(47.157745), z = 1200, zscale = 10, textsize = 40, linewidth = 4, text = "St Poltner Hutte", freetype = FALSE)
render_label(elev_matrix, x = xvec(12.392638), y = yvec(47.123220), z = 800, zscale = 10, textsize = 20, linewidth = 4, text = "Neue Prager Hutte", freetype = FALSE)
render_label(elev_matrix, x = xvec(12.345676), y = yvec(47.109409), z = 600, zscale = 10, textsize = 20, linewidth = 4, text = "Grossvenediger", freetype = FALSE)

# Add track and animate ---------------------------------------------------

# Plot the route in 3D
x <- xvec(gpx$lon)
y <- yvec(gpx$lat)
z <- gpx$ele
zscale <- 10

# Camera movements, borrowed from https://www.rdocumentation.org/packages/rayshader/versions/0.11.5/topics/render_movie
phivechalf = 30 + 60 * 1/(1 + exp(seq(-7, 20, length.out = 180)/2))
phivecfull = c(phivechalf, rev(phivechalf))
thetavec = 90 + 60 * sin(seq(0,359,length.out = 360) * pi/180)
zoomvec = 0.35 + 0.2 * 1/(1 + exp(seq(-5, 20, length.out = 180)))
zoomvecfull = c(zoomvec, rev(zoomvec))

# Progressive track rendering
setwd("Track")

for (i in 1:36) {
  rgl::lines3d(
    x[1:ceiling((1555/360)*i)],
    z[1:ceiling((1555/360)*i)]/(zscale-.05),
    -y[1:ceiling((1555/360)*i)],
    color = "red",
    lwd = 4,
    smooth = T,
    add = T
  )
  render_camera(theta = thetavec[i], phi = phivecfull[i], zoom = zoomvecfull[i], fov = 50)
  rgl::snapshot3d(paste0(i,".png"))
  rgl.pop(id = rgl.ids()$id %>% max())
}