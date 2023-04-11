import NCDatasets
import GRIBDatasets
import CommonDataModel as CDM
using Test

datadir = joinpath(dirname(pathof(GRIBDatasets)),"..","test","sample-data")
filename = joinpath(datadir,"era5-levels-members.grib")
ds = GRIBDatasets.Dataset(filename)

io = IOBuffer()
show(io,ds)
out = String(take!(io))
@test occursin("Global attributes",out)
@test occursin("CF-",out)

tmp_filename = tempname()
NCDatasets.write(tmp_filename,ds)

@test isfile(tmp_filename)

dsnc = NCDatasets.Dataset(tmp_filename)
@test ds["number"][:] == dsnc["number"][:]

@test CDM.dims(ds) == CDM.dims(dsnc)
@test CDM.attribs(ds) == CDM.attribs(dsnc)
@test CDM.groups(ds) == CDM.groups(dsnc)


close(dsnc)
# close(ds)
