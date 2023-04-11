using NCDatasets
using Test


fname = tempname()
ds = NCDataset(fname,"c")

data = Array{Union{Missing,Float32},2}(undef,10,10)
data .= 3
data[2,2] = missing

add_offset = 12.
scale_factor = 45
fill_value = 9999.f0

v = defVar(ds,"temp",data,("lon","lat"),attrib = Dict(
    "_FillValue" => fill_value,
    "add_offset" => add_offset,
    "scale_factor" => scale_factor))

v.var[1,1] = 1

@test v[1,1] ≈ scale_factor * v.var[1,1] + add_offset
@test ismissing(v[2,2])
@test fillvalue(v) == fill_value

close(ds)
