
#import NCDatasets
using CommonDataModel: SubDataset, SubVariable, chunking, deflate, path, @select, varnames
using CommonDataModel: MemoryDataset, defVar, groupby, select
using DataStructures, Dates
using Test


#TDS = NCDatasets.NCDataset
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

ncvar_view = view(ncvar,1:3,1:4)
@test parentindices(ncvar_view) == (1:3,1:4)
ncvar_view.attrib["foo"] = "bar"
@test ncvar_view.attrib["foo"] == "bar"
@test ncvar.attrib["foo"] == "bar"
@test Array(view(ncvar,:,:)) == data
@test ncscalar[] == 12

coords_names = CommonDataModel.coordinate_names(ncvar_view)
@test :lat in coords_names
@test :lon in coords_names

@test collect(view(ds,lon=1:3)["scalar"])[1] == 12

@test Array(view(ncvar,1:3,1:4)) == Array(view(data,1:3,1:4))

@test ncvar_view[CartesianIndex(2,3)] == data[CartesianIndex(2,3)]
@test ncvar_view[CartesianIndex(2),3] == data[2,3]


@test chunking(ncvar_view)[1] == :contiguous
@test chunking(ncvar_view)[2] == size(ncvar_view)
@test deflate(ncvar_view) == deflate(ncvar)

list_indices = [
    (:,:),(1:3,2:3),(2,:),(2,2:3),
    (1:3:10,2:3),
    (CartesianIndex(1,2):CartesianIndex(2,3),)
]

for indices = list_indices
    local v
    local ncvar2
    ncvar2 = data[indices...]
    v = view(ncvar,indices...);

    @test size(v) == size(ncvar2)
    @test Array(v) == ncvar2
end

ncvar2 = ncvar[:,2][1:2]
v = view(view(ncvar,:,2),1:2)

@test ncvar2 == v

data_view = view(view(data,:,1:2),1:2:6,:)
ncvar_view = view(view(ncvar,:,1:2),1:2:6,:)

@test data_view == Array(ncvar_view)
@test data_view == ncvar_view

ind = CartesianIndex(1,1)
@test ncvar_view[ind] == data_view[ind]

ind = CartesianIndices((1:2,1:2))
@test ncvar_view[ind] == data_view[ind]


@test ncvar[:,1:2][1:2:6,:] == Array(view(ncvar,:,1:2)[1:2:6,:])

ind = CartesianIndices((1:2,1:2))

@test ncvar[:,1:2][ind] == Array(view(ncvar,:,1:2)[ind])


# writing to a view

vdata = view(data,2:3,3:4)
vdata[2,:] = [1,1]

vncvar = view(ncvar,2:3,3:4)
vncvar[2,:] = [1,1]

@test data == collect(ncvar)

io = IOBuffer()
show(io,view(ncvar,:,:));
@test occursin("elevation",String(take!(io)))

# subset of dataset

indices = (lon = 3:4, lat = 1:3)

sds = SubDataset(ds,indices)

#test keys and varnames
@test keys(ds) == varnames(ds)
@test keys(sds) == varnames(sds)

@test size(sds["lon"]) == (2,)
@test size(sds["lat"]) == (3,)
@test size(sds["bat"]) == (2,3)

@test sds["bat"][2,2] == ds["bat"][4,2]

@test "lon" in keys(sds)

indices = (lon = 1:2,)
sds = SubDataset(ds,indices)
@test size(sds["lon"]) == (2,)
@test size(sds["lat"]) == (11,)
@test size(sds["bat"]) == (2,11)
@test sds.dim["lon"] == 2
@test sds.dim["lat"] == 11

io = IOBuffer()
show(io,sds);
@test occursin("lon = 2",String(take!(io)))


@test dimnames(view(ncvar,:,1)) == ("lon",)

close(ds)


# test view of TDS
ds = TDS(tempname(),"c")

# Declare variables

nclon = defVar(ds,"lon", 1:10, ("lon",))
nclat = defVar(ds,"lat", 1:11, ("lat",))
ncvar = defVar(ds,"bat", zeros(10,11), ("lon", "lat"), attrib = OrderedDict(
    "standard_name"             => "height",
))

ds_subset = view(ds, lon = 2:3, lat = 2:4)

fname_slice = tempname()
ds_slice = TDS(fname_slice,"c")
write(ds_slice,ds_subset)
close(ds_slice)

@test TDS(fname_slice)["lon"][:] == 2:3

close(ds)



#

fname = tempname()
ds = TDS(fname,"c")

nclon = defVar(ds,"lon", 1:7, ("lon",))
nclat = defVar(ds,"lat", 1:10, ("lat",))
nctime = defVar(ds,"time", [DateTime(2000,1,1)], ("time",))
ncsst = defVar(ds,"sst", ones(7,10,1), ("lon", "lat", "time"))

ncsst3 = @select(ncsst,lon ≈ 2 && lat ≈ 3)

ss = ncsst3["time"]
@test ss[1] == DateTime(2000,1,1)
@test ndims(view(ncsst,:,1,1)) == 1
close(ds)


## test groupby
fname = tempname()
ds = TDS(fname,"c")

nclon = defVar(ds,"lon", 1:7, ("lon",))
nclat = defVar(ds,"lat", 1:10, ("lat",))
times_array = collect(DateTime(2002,1,1):Day(1):DateTime(2002,3,20))

nctime = defVar(ds,"time", times_array, ("time",))
ncsst = defVar(ds,"sst", ones(7,10,length(times_array)), ("lon", "lat", "time"))

sst_view = view(ds["sst"],1:5,:1:4,:)
gv = groupby(sst_view,:time => Dates.Month)
sum_per_month = sum(gv)

@test size(sum_per_month) == (5,4,3)
@test all(sum_per_month[:,:,1] .≈ 31.0)
@test all(sum_per_month[:,:,2] .≈ 28.0)
@test all(sum_per_month[:,:,3] .≈ 20.0)

sst_view_time = view(ds["sst"],:,:,11:(length(times_array)-5))
gv = groupby(sst_view_time,:time => Dates.Month)
sum_per_month = sum(gv)
@test all(sum_per_month[:,:,1] .≈ 21.0)
@test all(sum_per_month[:,:,2] .≈ 28.0)
@test all(sum_per_month[:,:,3] .≈ 15.0)


## test select
sst2_data = ones(7,10,length(times_array)) # setup test var
sst2_data[:,:,1] .*= collect(1:7)
sst2_data[:,:,2] .*= collect(1:10)'
ncsst2 = defVar(ds,"sst2", sst2_data, ("lon", "lat", "time"))

sst_view = view(ds["sst2"],2:7,1:2:10,1:8)

v = select(sst_view,
           :lon => lon -> 1 <= lon <= 5,
           :lat => lat -> 2 <= lat <= 7)

@test size(v) == (4,3,8)
@test all(v[:,1,1] .≈ 2:5)
@test all(v[1,:,2] .≈ [3,5,7])


## regression test for https://github.com/JuliaGeo/NCDatasets.jl/issues/287
fname = tempname()
ds = TDS(fname, "c")
v = defVar(ds, "temperature", zeros(10,11), ("lon", "lat"))
m = iseven.(reshape(1:(10*11),(10,11)))

@test size(view(v,m)) == (count(m),)
v[m] .= 1
@test Array(v) == m