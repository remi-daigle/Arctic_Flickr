#This script plots density maps of 
# a) flickr photos across the Arctic 
# b) words used to tag flickr photos across the Arctic
# Follows on from Flickr_tidy_flickrtags.R & Flickr_googlecloudvision_label.r


wd <- "D:/Box Sync/Arctic/CONNECT/Paper_3_Flickr/Analysis/density_mapping/"
setwd(wd)
wd2 <- "D:/Box Sync/Arctic/Data"

### Setup ----
library(sf)
library(raster)
library(rgdal)

#options(stringsAsFactors = TRUE) #otherwise stat_density_2d throws an error
#options(tibble.width = Inf) #print all columns

#load country borders shp
#worldmap <- readOGR("D:/Box Sync/Arctic/Data/Boundaries/Arctic_circle/60degreesN/CountryBordersESRI_60degreesN_lambert.shp")
#load bounding box shp
boundary60N <- readOGR(paste0(wd2, "/Boundaries/Arctic_circle/60degreesN", "60degreesN"))
#load flickr points as .shp
load(paste0(dirname(wd), "/tag_analysis/output/Flickr_Artic_60N_plus_flickrandgooglelabels_userinfo_urban.Rdata"))
#flickrshp

##########################
### Preliminary processing ----
#turn boundary 60N into a raster
rcrs <- crs(boundary60N)

#drop photos pre 2004 and from 2018 or later
flickrshp <- flickrshp[flickrshp$year %in% as.factor(2004:2017), ]
#drop rows missing urls
flickrshp <- flickrshp[!is.na(flickrshp$url_m), ]
#Create a new column, user_date
flickrshp$owner_date <- paste(flickrshp$owner, flickrshp$datetkn, sep="_")
#drop testusers
flickrshpr <- flickrshp[flickrshp$usertype %in% c("superuser", "regular"), ] 

#convert to .shp
st_write(flickrshpr, paste0(wd2, "/Flickr/Flickr_Artic_60N_plus_flickrandgooglelabels_notestusers_2004to2017.shp"))

#read in shp
flickrshpr <- readOGR(paste0(wd2, "/Flickr/Flickr_Artic_60N_plus_flickrandgooglelabels_notestusers_2004to2017.shp"))


##########################
### Main processing 
##########################
# Make Rasters counting the number of photo-user-days (PUD) per cell ----
#set up function to rasterize points
rastFunPUD <- function(data, curres, currfolder, currphotos, currfile){
  rasttemplate <- raster(xmn=-3335000, xmx=3335000, ymn=-3335000, ymx=3335000, res=curres, crs=rcrs)
  if(file.exists(sprintf("%s/Boundaries/Arctic_circle/60degreesN/60degreesN_%sres.tif", wd2, currfile))==FALSE){ 
    rast60N <- rasterize(boundary60N, rasttemplate, filename=sprintf("D:/Box Sync/Arctic/Data/Boundaries/Arctic_circle/60degreesN/60degreesN_%sres.tif", currfile))
  } else {
    rast60N <- raster(sprintf("%s/Boundaries/Arctic_circle/60degreesN/60degreesN_%sres.tif", wd2, currfile))
  }
  rast60N[rast60N==1] <- 0
  densRast <- rasterize(data, rast60N, fun=function(x, ...){ length(unique(x))}, field="owner_date", update=TRUE, filename=sprintf("%s/Flickr_%s_per%scell.tif", currfolder, currphotos, currfile), overwrite=TRUE)
}

#maps of all points across all time
rast250m <- rastFunPUD(flickrshpr, 250, "static_rasters_pud", "allseasons_pud", "250m")
rast1km <- rastFunPUD(flickrshpr, 1000, "static_rasters_pud", "allseasons_pud", "1km")
rast5km <- rastFunPUD(flickrshpr, 5000, "static_rasters_pud", "allseasons_pud", "5km")
rast10km <- rastFunPUD(flickrshpr, 10000, "static_rasters_pud", "allseasons_pud", "10km")

#map photos from winter (Nov-Apr)
flickrshp_winter <- flickrshpr[flickrshpr$month %in% c("11", "12", "01", "02", "03", "04"), ]
rast10kmwinter <- rastFunPUD(flickrshp_winter, 10000, "static_rasters_pud", "winterphotos_pud", "10km")
#map photos from summer (May-Oct)
flickrshp_summer <- flickrshpr[flickrshpr$month %in% c("05", "06", "07", "08", "09", "10"),]
rast10kmsummer <- rastFunPUD(flickrshp_summer, 10000, "static_rasters_pud", "summerphotos_pud", "10km")


#annual maps
lapply(c(2001:2017), function(curryr) {
  data <- flickrshpr[flickrshpr$year==curryr, ]
  currfile <- paste0(curryr, "_5km")
  rastFunPUD(data=data, curres=5000, currfolder="annual_rasters_pud", currphotos="allseasons_pud", currfile=currfile)
})

#annual maps, high res
lapply(c(2001:2017), function(curryr) {
  data <- flickrshpr[flickrshpr$year==curryr, ]
  currfile <- paste0(curryr, "_250m")
  rastFunPUD(data=data, curres=250, currfolder="annual_rasters_pud", currphotos="allseasons_pud", currfile=currfile)
})

#annual maps - tourists, high res
flickrshpt <- flickrshpr[flickrshpr$touristtype=="tourist"]
lapply(c(2001:2017), function(curryr) {
  data <- flickrshpt[flickrshpt$year==curryr, ]
  currfile <- paste0(curryr, "_250m")
  rastFunPUD(data=data, curres=250, currfolder="annual_rasters_pud_tourists", currphotos="allseasons_pud_tourists", currfile=currfile)
})

#annual maps - locals, high res
flickrshpl <- flickrshpr[flickrshpr$touristtype=="local"]
lapply(c(2001:2017), function(curryr) {
  data <- flickrshpl[flickrshpl$year==curryr, ]
  currfile <- paste0(curryr, "_250m")
  rastFunPUD(data=data, curres=250, currfolder="annual_rasters_pud_locals", currphotos="allseasons_pud_locals", currfile=currfile)
})


##########################
#### Make rasters counting the number of photos per cell ----

#load flickr points as .shp
flickrshp <- readOGR("D:/Box Sync/Arctic/Data/Flickr/Flickr_Artic_60N_byregion_laea_icelandupdate.shp")

#drop photos pre 2001 and from 2018 or later
flickrshp <- flickrshp[flickrshp$year %in% as.factor(2001:2017), ]
#drop rows missing urls
flickrshp <- flickrshp[!is.na(flickrshp$url_m), ]
flickrshp$year <- droplevels(flickrshp$year)

#Create a new column, user_date
flickrshp@data$owner_date <- paste(flickrshp@data$owner, flickrshp@data$datetkn, sep="_")


#set up function to rasterize points
rastFun <- function(data, curres, currfolder, currphotos, currfile){
  rasttemplate <- raster(xmn=-3335000, xmx=3335000, ymn=-3335000, ymx=3335000, res=curres, crs=rcrs)
  if(file.exists(sprintf("D:/Box Sync/Arctic/Data/Boundaries/Arctic_circle/60degreesN/60degreesN_%sres.tif", currfile))==FALSE){ 
    rast60N <- rasterize(boundary60N, rasttemplate, filename=sprintf("D:/Box Sync/Arctic/Data/Boundaries/Arctic_circle/60degreesN/60degreesN_%sres.tif", currfile))
  } else {
    rast60N <- raster(sprintf("D:/Box Sync/Arctic/Data/Boundaries/Arctic_circle/60degreesN/60degreesN_%sres.tif", currfile))
  }
  rast60N[rast60N==1] <- 0
  densRast <- rasterize(data, rast60N, fun='count', field="id", update=TRUE, filename=sprintf("%s/Flickr_%s_per%scell.tif", currfolder, currphotos, currfile), overwrite=TRUE)
}

#maps of all points across all time
rast250m <- rastFun(flickrshp, 250, "static_rasters_nphotos", "allseasons", "250m")
rast1km <- rastFun(flickrshp, 1000, "static_rasters_nphotos", "allseasons", "1km")
rast5km <- rastFun(flickrshp, 5000, "static_rasters_nphotos", "allseasons", "5km")
rast10km <- rastFun(flickrshp, 10000, "static_rasters_nphotos", "allseasons", "10km")

#map photos from winter (Nov-Apr)
flickrshp_winter <- flickrshp[flickrshp$month %in% c("11", "12", "01", "02", "03", "04"), ]
rast10kmwinter <- rastFun(flickrshp_winter, 10000, "static_rasters_nphotos", "winterphotos", "10km")
#map photos from summer (May-Oct)
flickrshp_summer <- flickrshp[flickrshp$month %in% c("05", "06", "07", "08", "09", "10"),]
rast10kmsummer <- rastFun(flickrshp_summer, 10000, "static_rasters_nphotos", "summerphotos", "10km")

length(flickrshp_winter)
length(flickrshp_summer)

#annual maps
lapply(c(2001:2017), function(curryr) {
    data <- flickrshp[flickrshp$year==curryr, ]
    currfile <- paste0(curryr, "_5km")
    rastFun(data=data, curres=5000, currfolder="annual_rasters_nphotos", currphotos="allseasons_nphotos", currfile=currfile)
})

#annual maps, high res
lapply(c(2001:2017), function(curryr) {
    data <- flickrshp[flickrshp$year==curryr, ]
    currfile <- paste0(curryr, "_250m")
    rastFun(data=data, curres=250, currfolder="annual_rasters_nphotos", currphotos="allseasons_nphotos", currfile=currfile)
})

##########################
# Make Rasters counting the number of owners per cell ----
#set up function to rasterize points
rastFunOwner <- function(data, curres, currfolder, currphotos, currfile){
  rasttemplate <- raster(xmn=-3335000, xmx=3335000, ymn=-3335000, ymx=3335000, res=curres, crs=rcrs)
  if(file.exists(sprintf("D:/Box Sync/Arctic/Data/Boundaries/Arctic_circle/60degreesN/60degreesN_%sres.tif", currfile))==FALSE){ 
    rast60N <- rasterize(boundary60N, rasttemplate, filename=sprintf("D:/Box Sync/Arctic/Data/Boundaries/Arctic_circle/60degreesN/60degreesN_%sres.tif", currfile))
  } else {
    rast60N <- raster(sprintf("D:/Box Sync/Arctic/Data/Boundaries/Arctic_circle/60degreesN/60degreesN_%sres.tif", currfile))
  }
  rast60N[rast60N==1] <- 0
  densRast <- rasterize(data, rast60N, fun=function(x, ...){ length(unique(x))}, field="owner", update=TRUE, filename=sprintf("%s/Flickr_%s_per%scell.tif", currfolder, currphotos, currfile), overwrite=TRUE)
}

#maps of all points across all time
rast250m <- rastFunOwner(flickrshp, 250, "static_rasters_nowners", "allseasons_nowners", "250m")
rast1km <- rastFunOwner(flickrshp, 1000, "static_rasters_nowners", "allseasons_nowners", "1km")
rast5km <- rastFunOwner(flickrshp, 5000, "static_rasters_nowners", "allseasons_nowners", "5km")
rast10km <- rastFunOwner(flickrshp, 10000, "static_rasters_nowners", "allseasons_nowners", "10km")

#map photos from winter (Nov-Apr)
flickrshp_winter <- flickrshp[flickrshp$month %in% c("11", "12", "01", "02", "03", "04"), ]
rast10kmwinter <- rastFunOwner(flickrshp_winter, 10000, "static_rasters_nowners", "winterphotos_nowners", "10km")
#map photos from summer (May-Oct)
flickrshp_summer <- flickrshp[flickrshp$month %in% c("05", "06", "07", "08", "09", "10"),]
rast10kmsummer <- rastFunOwner(flickrshp_summer, 10000, "static_rasters_nowners", "summerphotos_nowners", "10km")

length(unique(flickrshp_winter$owner))
length(unique(flickrshp_summer$owner))

#annual maps
lapply(c(2001:2017), function(curryr) {
  data <- flickrshp[flickrshp$year==curryr, ]
  currfile <- paste0(curryr, "_5km")
  rastFunOwner(data=data, curres=5000, currfolder="annual_rasters_nowners", currphotos="allseasons_nowners", currfile=currfile)
})

#annual maps, high res
lapply(c(2001:2017), function(curryr) {
  data <- flickrshp[flickrshp$year==curryr, ]
  currfile <- paste0(curryr, "_250m")
  rastFunOwner(data=data, curres=250, currfolder="annual_rasters_nowners", currphotos="allseasons_nowners", currfile=currfile)
})

#END#############