#using NCDatasets
using Test
import CommonDataModel as CDM
using DataStructures
using Dates
import CommonDataModel: AbstractDataset, AbstractVariable, Attributes, Dimensions, CatArrays, defGroup, sync, chunking, deflate, checksum

function example_file(TDS,i,array, fname = tempname();
    varname = "var")

    @debug "fname $fname"

    TDS(fname,"c") do ds
        # Dimensions

        ds.dim["lon"] = size(array,1)
        ds.dim["lat"] = size(array,2)
        ds.dim["time"] = Inf

        # Declare variables

        ncvar = defVar(ds,varname, Float64, ("lon", "lat", "time"),
                       fillvalue = -9999.0)
        ncvar.attrib["field"] = "u-wind, scalar, series"
        ncvar.attrib["units"] = "meter second-1"
        ncvar.attrib["long_name"] = "surface u-wind component"
        ncvar.attrib["time"] = "time"
        ncvar.attrib["coordinates"] = "lon lat"


        nclat = defVar(ds,"lat", Float64, ("lat",))
        nclat.attrib["units"] = "degrees_north"

        nclon = defVar(ds,"lon", Float64, ("lon",))
        nclon.attrib["units"] = "degrees_east"
        nclon.attrib["modulo"] = 360.0

        nctime = defVar(ds,"time", Float64, ("time",), attrib = OrderedDict(
            "long_name" => "surface wind time",
            "field" => "time, scalar, series",
            "units" => "days since 2000-01-01 00:00:00",
            "standard_name" => "time",
        ))
        # Global attributes

        ds.attrib["history"] = "foo"

        # Define variables

        g = defGroup(ds,"group")

        ncvarg = defVar(g,varname, Float64, ("lon", "lat", "time"),
                        attrib = OrderedDict(
                            "field" => "u-wind, scalar, series",
                            "units" => "meter second-1",
                            "long_name" => "surface u-wind component",
                            "time" => "time",
                            "coordinates" => "lon lat",
                        ))

        ncvar[:,:,1] = array
        ncvarg[:,:,1] = array.+1
        #nclon[:] = 1:size(array,1)
        #nclat[:] = 1:size(array,2)
        nctime.var[1] = i

        nclon[:] = 1:size(array,1)
        nclat[:] = 1:size(array,2)
    end
    return fname
end

TDS = MemoryDataset
#TDS = NCDataset


A = [randn(2,3),randn(2,3),randn(2,3)]

C = cat(A...; dims = 3)
CA = CatArrays.CatArray(3,A...)

idx_global_local = CatArrays.index_global_local(CA,(1:1,1:1,1:1))

@inferred CatArrays.index_global_local(CA,(1:1,1:1,1:1))

@test CA[1:1,1:1,1:1] == C[1:1,1:1,1:1]
@test CA[1:1,1:1,1:2] == C[1:1,1:1,1:2]
@test CA[1:2,1:1,1:2] == C[1:2,1:1,1:2]


@test CA[:,:,1] == C[:,:,1]
@test CA[:,:,2] == C[:,:,2]
@test CA[:,2,:] == C[:,2,:]
@test CA[:,1:2:end,:] == C[:,1:2:end,:]
@test CA[1,1,1] == C[1,1,1]

@test CA[1,1,[1,2]] == C[1,1,[1,2]]
@test CA[1,1,[1,3]] == C[1,1,[1,3]]
@test CA[1,[1,3],:] == C[1,[1,3],:]


CA[2,2,:] = [1.,2.,3.]
@test A[1][2,2] == 1.
@test A[2][2,2] == 2.
@test A[3][2,2] == 3.



A = [rand(0:99,2,3,3),rand(0:99,2,3),rand(0:99,2,3)]
C = cat(A...; dims = 3)
CA = CatArrays.CatArray(3,A...)
@test CA[1,1,[1,2,4]] == C[1,1,[1,2,4]]
@test CA[1,1,[4,1,4]] == C[1,1,[4,1,4]]



A = [randn(2,3),randn(2,3),randn(2,3)]
C = cat(A...; dims = 3)
fnames = example_file.(TDS,1:3,A)

varname = "var"

for deferopen in (false,true)
    local mfds, data
    local lon
    local buf, ds_merged, fname_merged, var

    mfds = TDS(fnames, deferopen = deferopen);
    var = variable(mfds,varname);
    data = var[:,:,:]
    @test C == var[:,:,:]

    @test_throws BoundsError var[:,:,end+1]
    @test_throws BoundsError mfds[varname].var[:,:,end+1]

    @test mfds.attrib["history"] == "foo"
    @test var.attrib["units"] == "meter second-1"

    @test dimnames(var) == ("lon", "lat", "time")
    # lon does not vary in time and thus there should be no aggregation
    lon = variable(mfds,:lon);
    @test lon.attrib["units"] == "degrees_east"
    @test size(lon) == (size(data,1),)

    var = mfds[varname]
    @test C == var[:,:,:]
    @test dimnames(var) == ("lon", "lat", "time")

    @test mfds.dim["lon"] == size(C,1)
    @test mfds.dim["lat"] == size(C,2)
    @test mfds.dim["time"] == size(C,3)

    @test mfds.dim["time"] == size(C,3)

    # save a aggregated file
    ds_merged = TDS(tempname(),"c")
    write(ds_merged,mfds)

    @test mfds.dim["time"] == size(C,3)
    @test mfds["time"][:] == ds_merged["time"][:]
    @test mfds["lon"][:] == ds_merged["lon"][:]
    @test name(mfds[CF"time"]) == "time"
    close(ds_merged)


    # save subset of aggregated file
    fname_merged = tempname()
    ds_merged = TDS(fname_merged,"c")
    write(ds_merged,view(mfds,lon = 1:1))
    @test mfds["lon"][1:1] == ds_merged["lon"][:]
    close(ds_merged)

#=
    # save subset of aggregated file (deprecated)
    fname_merged = tempname()
    write(fname_merged,mfds,idimensions = Dict("lon" => 1:1))
    ds_merged = TDS(fname_merged)
    @test mfds["lon"][1:1] == ds_merged["lon"][:]
    close(ds_merged)
=#
    # show
    buf = IOBuffer()
    show(buf,mfds)
    occursin("time = 3",String(take!(buf)))

    close(mfds)
end

# write
mfds = TDS(fnames,"a",deferopen = false);
mfds[varname][2,2,:] = 1:length(fnames)
mfds.attrib["history"] = "foo2"
mfds.attrib["new"] = "attrib"
@test TDS(fnames[2]).attrib["new"]  == "attrib"

@test name(parentdataset(mfds.group["group"])) == "/"

@test chunking(mfds[varname]) == (:contiguous, (2, 3, 3))
@test deflate(mfds[varname]) == (false, false, 0)
@test checksum(mfds[varname]) == :nochecksum

@test_throws ArgumentError TDS(fnames,"not-a-mode")

@test collect(keys(mfds)) == [varname, "lat", "lon", "time"]
@test keys(mfds.dim) == ["lon", "lat", "time"]
@test name(mfds) == "/"
@test size(mfds[varname]) == (2, 3, 3)
@test size(mfds[varname].var) == (2, 3, 3)
@test name(mfds[varname].var) == varname
@test name(mfds.group["group"]) == "group"
@test fillvalue(mfds[varname]) == -9999.
@test fillvalue(mfds[varname].var) == -9999.
@test dataset(mfds[varname]) == mfds


# create new dimension in all files
mfds.dim["newdim"] = 123;
sync(mfds)
close(mfds)

for n = 1:length(fnames)
    TDS(fnames[n]) do ds
        @test ds[varname][2,2,1] == n
    end
end

TDS(fnames[1]) do ds
    @test ds.attrib["history"] == "foo2"
end

TDS(fnames[1]) do ds
    @test ds.dim["newdim"] == 123
end

# multi-file merge

ampl = rand(50,50)
vel = rand(50,50)

fnames = [example_file(TDS, 1, vel; varname = "vel"),
          example_file(TDS, 1, ampl; varname = "ampl")]

ds = TDS(fnames,aggdim = "", deferopen = false);

@test ds["ampl"][:,:,1] == ampl
@test ds["vel"][:,:,1] == vel

@test sort(keys(ds)) == ["ampl", "lat", "lon", "time", "vel"]


# save a merged file
fname_merged = tempname()
TDS(fname_merged,"c") do ds_dest
    write(ds_dest,ds)
end

ds_merged = TDS(fname_merged)
@test sort(collect(keys(ds_merged))) == ["ampl", "lat", "lon", "time", "vel"]
@test ds_merged["ampl"][:,:,1] == ampl
@test ds_merged["vel"][:,:,1] == vel
close(ds_merged)
nothing



# multi-file with different time units
fnames = [tempname(), tempname()]
times = [DateTime(2000,1,1), DateTime(2000,1,2)]
time_units = ["days since 2000-01-01","seconds since 2000-01-01"]

for i = 1:2
    local ds
    ds = TDS(fnames[i],"c")
    defVar(ds,"time",times[i:i],("time",),attrib = Dict(
        "units" => time_units[i],
        "scale_factor" => Float64(10*i),
        "add_offset" => Float64(i),
    ))
    close(ds)
end

ds = TDS(fnames,aggdim = "time")
ds["time"][:] == times
close(ds)


# test cat

A = [randn(2,3),randn(2,3),randn(2,3)]
C = cat(A...; dims = 3)
fnames = example_file.(TDS, 1:3,A)
ds =  TDS.(fnames)
vars = getindex.(ds,"var")
a = cat(vars...,dims=3);

close.(ds)

ds = TDS(fnames,aggdim = "new_dim", isnewdim = true)
@test ds.dim["new_dim"] == length(fnames)

@test ds["var"][:,:,:,:] == cat(A...; dims = 4)
@test size(ds["lon"]) == (size(A[1],1),length(A))
close(ds)

ds = TDS(fnames,aggdim = "new_dim", constvars = ["lon","lat"],
               isnewdim = true)
@test ds["var"][:,:,:,:] == cat(A...; dims = 4)
@test ds.dim["new_dim"] == length(fnames)
@test size(ds["lon"]) == (size(A[1],1),)
@test size(ds["lat"]) == (size(A[1],2),)
close(ds)
