import Base
import CommonDataModel as CDM
using DataStructures


struct MemoryVariable{T,N,TP} <: CDM.AbstractVariable{T,N}
    parent_dataset::TP
    name::String
    dimnames::NTuple{N,String}
    data::Array{T,N}
    attrib::OrderedDict{String,Any}
end

struct MemoryDataset <: CDM.AbstractDataset
    dim::OrderedDict{String,Int}
    variables::OrderedDict{String,MemoryVariable}
    attrib::OrderedDict{String,Any}
    unlimited::Vector{String}
end

Base.getindex(v::MemoryVariable,ij...) = v.data[ij...]
Base.setindex!(v::MemoryVariable,data,ij...) = v.data[ij...] = data
CDM.dataset(v::MemoryVariable) = v.parent_dataset
CDM.name(v::MemoryVariable) = v.name
CDM.dimnames(v::MemoryVariable) = v.dimnames
Base.size(v::MemoryVariable) = size(v.data)
CDM.dim(v::MemoryVariable,name::AbstractString) = v.parent_dataset.dim[name]

Base.keys(md::MemoryDataset) = keys(md.variables)
CDM.variable(md::MemoryDataset,varname::AbstractString) = md.variables[varname]
Base.getindex(md::MemoryDataset,varname::AbstractString) = CDM.cfvariable(md,varname)
CDM.dimnames(md::MemoryDataset) = keys(md.dim)
CDM.dim(md::MemoryDataset,name::AbstractString) = md.dim[name]
CDM.attribnames(md::Union{MemoryDataset,MemoryVariable}) = keys(md.attrib)
CDM.attrib(md::Union{MemoryDataset,MemoryVariable},name::AbstractString) = md.attrib[name]

function CDM.defDim(md::MemoryDataset,name::AbstractString,len)
    if isinf(len)
        @warn "unlimited dimensions are not supported yet"
        md.dim[name] = 0
        push!(unlimited,name)
    else
        md.dim[name] = len
    end
end

function CDM.defVar(md::MemoryDataset,name::AbstractString,T,dimnames;
                    attrib = OrderedDict{String,Any}(),
                    )
    sz = ntuple(i -> CDM.dim(md,dimnames[i]),length(dimnames))
    data = Array{T,length(dimnames)}(undef,sz...)
    mv = MemoryVariable(md,name,(dimnames...,), data, attrib)
    md.variables[name] = mv

    return md[name] # return CFVariable
end

function CDM.defAttrib(md::Union{MemoryVariable,MemoryDataset},name::AbstractString,data);
    md.attrib[name] = data
end

function MemoryDataset()
    return MemoryDataset(
        OrderedDict{String,Int}(),
        OrderedDict{String,MemoryVariable}(),
        OrderedDict{String,Any}(),
        String[])
end

