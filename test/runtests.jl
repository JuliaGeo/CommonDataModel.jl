import NCDatasets
import GRIBDatasets
using CommonDataModel
using Test

datadir = joinpath(dirname(pathof(GRIBDatasets)),"..","test","sample-data")
filename = joinpath(datadir,"era5-levels-members.grib")
ds = GRIBDatasets.Dataset(filename)
tmp_filename = tempname()

@test_broken begin
    NCDatasets.write(tmp_filename,ds)
    @assert isfile(tmp_filename)
end


