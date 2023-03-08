
using NCDatasets
using GRIBDatasets
using AbstractDatasets

ds2 = NCDataset("/home/abarth/ROMS-implementation-test.bak/liguriansea2019_Pair.nc")
#dimnames(ds2["Pair"])



ds = GRIBDataset("/home/abarth/.local/lib/python3.10/site-packages/xarray/tests/data/example.grib")

GRIBDatasets.dimnames(ds["z"])

grib_var = ds["z"]

eltype(grib_var.var)


dimnames(ds["z"])


NCDatasets.write("/tmp/test.nc",ds)
