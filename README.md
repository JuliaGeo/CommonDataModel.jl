[![Build Status](https://github.com/JuliaGeo/CommonDataModel.jl/workflows/CI/badge.svg)](https://github.com/JuliaGeo/CommonDataModel.jl/actions)
[![codecov.io](http://codecov.io/github/JuliaGeo/CommonDataModel.jl/coverage.svg?branch=main)](http://app.codecov.io/github/JuliaGeo/CommonDataModel.jl?branch=main)
[![documentation stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliageo.github.io/CommonDataModel.jl/stable/)
[![documentation dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliageo.github.io/CommonDataModel.jl/dev/)


This package contains abstracts type definition for loading and manipulating GRIB, NetCDF, geoTiff and Zarr files. This package aims to follow the [Common Data Model](https://docs.unidata.ucar.edu/netcdf-c/current/netcdf_data_model.html) and the [CF (climate and forecast models) Metadata Conventions](https://cfconventions.org/).


| Format  |      Package | read support | write support |
|---------|--------------|:------------:|:-------------:|
| NetCDF  | [`NCDatasets`](https://github.com/Alexander-Barth/NCDatasets.jl)     |            ✔ |             ✔ |
| OPeNDAP | [`NCDatasets`](https://github.com/Alexander-Barth/NCDatasets.jl)     |            ✔ |             - |
| GRIB    | [`GRIBDatasets`](https://github.com/JuliaGeo/GRIBDatasets.jl)        |            ✔ |             - |
| geoTIFF | [`TIFFDatasets`](https://github.com/Alexander-Barth/TIFFDatasets.jl) |            ✔ |             - |
| Zarr    | [`ZarrDatasets`](https://github.com/JuliaGeo/ZarrDatasets.jl)        |            ✔ |             ✔ |


Features include:
* query and edit metadata of arrays and datasets 
* virtually concatenating multiple files along a given dimension
* create a virtual subset (`view`) by indices or by values of coordinate variables (`CommonDataModel.select`, `CommonDataModel.@select`)
* group, map and reduce a variable (`CommonDataModel.groupby`, `CommonDataModel.@groupby`) and rolling reductions like running means `CommonDataModel.rolling`)




Here is minimal example for loading GRIB or NetCDF files.

``` julia
import CommonDataModel as CDM
import SomeDatasets # where SomeDatasets is either GRIBDatasets or NCDatasets

ds = SomeDatasets.Dataset("file_name")

# ntime is the number of time instances
ntime = ds.dim["time"] # or CDM.dims(ds)["time"]

# create an array-like structure v corresponding to variable temperature
v = ds["temperature"]

# load a subset
subdata = v[10:30,30:5:end]

# load all data
data = v[:,:]

# load a global attribute
title = ds.attrib["title"]  # or CDM.attribs(ds)["title"]
close(ds)
```

 Most users would typically import [`GRIBDatasets`](https://github.com/JuliaGeo/GRIBDatasets.jl) and [`NCDatasets`](https://github.com/Alexander-Barth/NCDatasets.jl) directly and not `CommonDataModel`. One should import `CommonDataModel` only to extent the functionality of `GRIBDatasets` and `NCDatasets`.



# File conversions

By implementing a common interface, GRIB files can be converted to NetCDF files using
`NCDatasets.write`:

```julia
using NCDatasets
using GRIBDatasets
using Downloads: download

grib_file = download("https://github.com/JuliaGeo/GRIBDatasets.jl/raw/98356af026ea39a5ec0b5e64e4289105492321f8/test/sample-data/era5-levels-members.grib")
netcdf_file = "test.nc"
NCDataset(netcdf_file,"c") do ds
   NCDatasets.write(ds,GRIBDataset(grib_file))
end
```
