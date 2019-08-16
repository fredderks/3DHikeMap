# 3D Hike Map
After completing a multi-day hike I did with my family in the Austrian Alps I felt inspired by [Elizabeth Easter](https://github.com/edeaster/Routes3D) to visualize our four-day trek above the valley floor and eventually up the glacier to the summit of the Großvenediger (3666m a.s.l.) using R and Rayshader

![Grossvenediger Route Demo](demo/hike_route.gif)

## GPS Route
I did not track the route using a smartwatch in this case as I do not own one, I have simply created a route on [Alpenvereinaktiv.de](https://www.alpenvereinaktiv.com/de/tour/huettentour-grossvenediger-ueber-hoeheweg/120138373/) From there the .gpx file is available for download. 
However, you can easily modify this script to accept .gpx files exported from your phone, watch or GPS device.

## Creating 3D Environment
A rectangular bounding box is created around the coordinates of the gps route. To create a 3D representation of the mountains, elevation data is downloaded from [Amazon Web Services Terrain Tiles](https://aws.amazon.com/public-datasets/terrain/) using the [`elevatr`](https://cran.r-project.org/web/packages/elevatr/vignettes/introduction_to_elevatr.html#usgs_elevation_point_query_service) package

A satellite image overlay is downloaded using the [ArcGIS REST API](https://developers.arcgis.com/rest/services-reference/export-web-map-task.htm) with some help from functions written by [Will Bishop](https://github.com/wcmbishop/rayshader-demo/blob/master/R/map-image-api.R)

Finally, the 3D object is plotted with `rgl` and shading is added using the [`rayshader`](https://www.rayshader.com) package, some labels are added and the route is progressively rendered.
The resulting .png files can then be combined into a video or .gif using your favourite software, I used Adobe Premiere Pro CC.

The final video can be found on [YouTube](https://www.youtube.com/watch?v=GELk-G69tzc)
