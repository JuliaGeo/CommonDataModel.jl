import Base
import CommonDataModel as CDM
#import CommonDataModel: SymbolOrString
using DataStructures
import CommonDataModel: defVar, unlimited, name, dimnames, dataset, variable, dim, attribnames, attrib, defDim, defAttrib

struct MemoryVariable{T,N,TP,TA <: AbstractArray{T,N}} <: CDM.AbstractVariable{T,N}
    parent_dataset::TP
    name::String
    dimnames::NTuple{N,String}
    data::TA
    _attrib::OrderedDict{String,Any}
end

struct MemoryDataset <: CDM.AbstractDataset
    dim::OrderedDict{String,Int}
    variables::OrderedDict{String,MemoryVariable}
    _attrib::OrderedDict{String,Any}
    unlimited::Vector{String}
end

Base.getindex(v::MemoryVariable,ij...) = v.data[ij...]
Base.setindex!(v::MemoryVariable,data,ij...) = v.data[ij...] = data
Base.size(v::MemoryVariable) = size(v.data)
CDM.name(v::MemoryVariable) = v.name
CDM.dimnames(v::MemoryVariable) = v.dimnames
CDM.dataset(v::MemoryVariable) = v.parent_dataset

Base.keys(md::MemoryDataset) = keys(md.variables)
CDM.variable(md::MemoryDataset,varname::AbstractString) = md.variables[varname]
CDM.dimnames(md::MemoryDataset) = keys(md.dim)
CDM.dim(md::MemoryDataset,name::AbstractString) = md.dim[name]
CDM.attribnames(md::Union{MemoryDataset,MemoryVariable}) = keys(md._attrib)
CDM.attrib(md::Union{MemoryDataset,MemoryVariable},name::AbstractString) = md._attrib[name]

function CDM.defDim(md::MemoryDataset,name::AbstractString,len)
    if isinf(len)
        @warn "unlimited dimensions are not supported yet"
        md.dim[name] = 0
        push!(unlimited,name)
    else
        md.dim[name] = len
    end
end

function CDM.defVar(md::MemoryDataset,name::AbstractString,T::DataType,dimnames;
                    attrib = OrderedDict{String,Any}(),
                    )
    sz = ntuple(i -> CDM.dim(md,dimnames[i]),length(dimnames))
    data = Array{T,length(dimnames)}(undef,sz...)
    mv = MemoryVariable(md,name,(dimnames...,), data,
                        convert(OrderedDict{String,Any},attrib))
    md.variables[name] = mv

    return md[name] # return CFVariable
end

function CDM.defAttrib(md::Union{MemoryVariable,MemoryDataset},name::AbstractString,data);
    md._attrib[name] = data
end

function MemoryDataset()
    return MemoryDataset(
        OrderedDict{String,Int}(),
        OrderedDict{String,MemoryVariable}(),
        OrderedDict{String,Any}(),
        String[])
end
