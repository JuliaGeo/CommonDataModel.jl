

This package contains abstracts type definition to ensure compatibility of the package [GRIBDatasets](https://github.com/JuliaGeo/GRIBDatasets.jl) and [NCDatasets](https://github.com/Alexander-Barth/NCDatasets.jl] for manipulating GRIB and NetCDF files. This package aims to follow the [Common Data Model](https://docs.unidata.ucar.edu/netcdf-c/current/netcdf_data_model.html) and the [CF (climate and forecast models) Metadata Conventions](https://cfconventions.org/).


Here is minimal example for loading such files.

``` julia
using SomeDatasets # where SomeDatasets is either GRIBDatasets or NCDatasets

ds = SomeDatasets.Dataset("file_name","r")

# ntime is the number of time instances
ntime = ds.dim["time"]

v = ds["temperature"]

# load a subset
subdata = v[10:30,30:5:end]

# load all data
data = v[:,:]

# load a global attribute
title = ds.attrib["title"]
close(ds)
```

Most users would typically import `GRIBDatasets` and `NCDatasets` directly and not `AbstractDatasets`. One should import `AbstractDatasets` only to extent the functionality of `GRIBDatasets` and `NCDatasets`.

A data set `ds` of a type derived from `AbstractDatasets` should implemented at minimum:

* `Base.key(ds)`: return a list of variable names a strings
* `Base.getindex(ds,varname::String)`: return an array-like data structure (derived from `AbstractDatasetVariable`) of the variables corresponding to `varname`. This array-like data structure should follow the CF semantics.
* `ds.attrib`: should be a Dict-like data structure with all attribute names as keys and the corresponding value
* `ds.dim`: should be a Dict-like data structure with all dimension names as keys and the corresponding length


`AbstractDatasetVariable{T,N}` is a subclass of `AbstractArray{T, N}`. A variable `v` of a type derived from `AbstractDatasetVariable` should implement:

* `v.attrib`: should be a Dict-like data structure with all attribute names as keys and the corresponding value
