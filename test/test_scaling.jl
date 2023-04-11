using NCDatasets
using Test
import CommonDataModel as CDM
using DataStructures
using Dates

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

@test collect(CDM.dimnames(v)) == ["lon","lat"]

#@test CDM.dim(v,"lon") == 10

io = IOBuffer()
CDM.show(io,"text/plain",v)
@test occursin("Attributes",String(take!(io)))

v = @test_warn "numeric" defVar(ds,"temp2",data,("lon","lat"),attrib = Dict(
    "missing_value" => "bad_idea"))

struct MemoryVariable{T,N} <: CDM.AbstractVariable{T,N}
    name::String
    dimnames::Vector{String}
    data::Array{T,N}
    attrib::OrderedDict{String,Any}
end

struct MemoryDataset <: CDM.AbstractDataset
    dim::OrderedDict{String,Int}
    variables::OrderedDict{String,MemoryVariable}
    attrib::OrderedDict{String,Any}
    unlimited::Vector{String}
end

data = rand(-100:100,30,31)
mv = MemoryVariable("data",["lon","lat"], data, OrderedDict{String,Any}(
    "units" => "days since 2000-01-01"))

Base.getindex(v::MemoryVariable,ij...) = v.data[ij...]
Base.setindex!(v::MemoryVariable,data,ij...) = v.data[ij...] = data
CDM.name(v::MemoryVariable) = v.name
CDM.dimnames(v::MemoryVariable) = v.dimnames
Base.size(v::MemoryVariable) = size(v.data)

@test "lon" in CDM.dimnames(mv)
@test CDM.name(mv) == "data"

md = MemoryDataset(
    OrderedDict{String,Int}(
        "lon" => 30,
        "lat" => 31),
    OrderedDict{String,MemoryVariable}(
        "data" => mv),
    OrderedDict{String,Any}(
        "history" => "lala"),
    String[])

import Base
Base.keys(md::MemoryDataset) = keys(md.variables)
CDM.variable(md::MemoryDataset,varname::AbstractString) = md.variables[varname]
Base.getindex(md::MemoryDataset,varname::AbstractString) = CDM.cfvariable(md,varname)
CDM.dimnames(md::MemoryDataset) = keys(md.dim)
CDM.dim(md::MemoryDataset,name::AbstractString) = md.dim[name]
CDM.attribnames(md::Union{MemoryDataset,MemoryVariable}) = keys(md.attrib)
CDM.attrib(md::Union{MemoryDataset,MemoryVariable},name::AbstractString) = md.attrib[name]


time_origin = DateTime(2000,1,1)
@test md["data"][1,1] == time_origin + Dates.Millisecond(data[1,1]*24*60*60*1000)

md["data"][1,2] = DateTime(2000,2,1)
@test md["data"].var[1,2] == Dates.value(md["data"][1,2] - time_origin) ÷ (24*60*60*1000)

io = IOBuffer()
CDM.show(io,md)
@test occursin("Attributes",String(take!(io)))


#close(ds)
