using Test
import DiskArrays
using DataStructures
using CommonDataModel
using CommonDataModel:
    MemoryDataset, defVar


@test CommonDataModel.AbstractVariable <: AbstractArray
@test CommonDataModel.CFVariable <: CommonDataModel.AbstractVariable
@test CommonDataModel.AbstractVariable <: DiskArrays.AbstractDiskArray
@test CommonDataModel.SubVariable <: DiskArrays.AbstractDiskArray

# create test data 
TDS = MemoryDataset
fname = tempname()

ds = TDS(fname,"c", attrib = OrderedDict(
    "title"                     => "title",
));

# Dimensions
ds.dim["lon"] = 10
ds.dim["lat"] = 11

# Declare variables

nclon = defVar(ds,"lon", Float64, ("lon",), attrib = OrderedDict(
    "long_name"                 => "Longitude",
    "standard_name"             => "longitude",
    "units"                     => "degrees_east",
))

nclat = defVar(ds,"lat", Float64, ("lat",), attrib = OrderedDict(
    "long_name"                 => "Latitude",
    "standard_name"             => "latitude",
    "units"                     => "degrees_north",
))

ncvar = defVar(ds,"bat", Float32, ("lon", "lat"), attrib = OrderedDict(
    "long_name"                 => "elevation above sea level",
    "standard_name"             => "height",
    "units"                     => "meters",
    "_FillValue"                => Float32(9.96921e36),
))

ncscalar = defVar(ds,"scalar", 12, ())

# Define variables

data = rand(Float32,10,11)

nclon[:] = 1:10
nclat[:] = 1:11
ncvar[:,:] = data

# test broadcast on variable
@test nclon isa DiskArrays.AbstractDiskArray
in_lon = nclon .< 5
@test in_lon isa DiskArrays.BroadcastDiskArray
@test ncvar[in_lon,:] == data[in_lon,:]

# test view of variable
sub_var = view(ncvar,3:7,1:2:11)
@test sub_var isa DiskArrays.AbstractSubDiskArray
@test (sub_var .+ 2) isa DiskArrays.BroadcastDiskArray

# test getting related variable of view
@test sub_var["lat"] isa DiskArrays.AbstractSubDiskArray
@test sub_var["lat"][:] == nclat[1:2:11]
@test sub_var["lon"][:] == nclat[3:7]

# test write to view.
sub_var["lon"][1:2] .= 17 
@test all(nclon[3:4] .== 17)

# test attrib of view
@test sub_var.attrib == ncvar.attrib
