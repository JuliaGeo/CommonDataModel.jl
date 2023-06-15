"""
    CommonDataModel.name(v::AbstractVariable)

Return the name of the variable `v` as a string.
"""
name(v::AbstractVariable) = ""


"""
    CommonDataModel.dimnames(v::AbstractVariable)

Return an iterable of the dimension names of the variable `v`.
"""
dimnames(av::AbstractVariable) = ()


"""
    CommonDataModel.varnames(ds::AbstractDataset)

Return an iterable of all the variable name.
"""
varnames(ds::AbstractDataset) = ()

"""
    CommonDataModel.variable(ds::AbstractDataset,variablename::SymbolOrString)

Return the variable with the name `variablename` from the data set `ds`.
"""
function variable(ds::AbstractDataset,variablename::SymbolOrString)
    error("no variable $variablename in $(path(ds)) (abstract method)")
end

function defVar(ds::AbstractDataset,name::SymbolOrString,type::DataType,
                dimnames)
    error("unimplemented for abstract type")
end




# data has the type e.g. Array{Union{Missing,Float64},3}
function defVar(ds::AbstractDataset,
                name::SymbolOrString,
                data::AbstractArray{Union{Missing,T},N},
                dimnames;
                kwargs...) where T <: Union{Int8,UInt8,Int16,Int32,Int64,Float32,Float64} where N
    _defVar(ds::AbstractDataset,name,data,T,dimnames; kwargs...)
end

# data has the type e.g. Vector{DateTime}, Array{Union{Missing,DateTime},3} or
# Vector{DateTime360Day}
# Data is always stored as Float64 in the NetCDF file
function defVar(ds::AbstractDataset,
                name::SymbolOrString,
                data::AbstractArray{<:Union{Missing,T},N},
                dimnames;
                kwargs...) where T <: Union{DateTime,AbstractCFDateTime} where N
    _defVar(ds::AbstractDataset,name,data,Float64,dimnames; kwargs...)
end

function defVar(ds::AbstractDataset,name::SymbolOrString,data,dimnames; kwargs...)
    # eltype of a String would be Char
    if data isa String
        nctype = String
    else
        nctype = eltype(data)
    end
    _defVar(ds::AbstractDataset,name,data,nctype,dimnames; kwargs...)
end

function _defVar(ds::AbstractDataset,name::SymbolOrString,data,nctype,vardimnames; attrib = [], kwargs...)
    # define the dimensions if necessary
    for (i,dimname) in enumerate(vardimnames)
        if !(dimname in dimnames(ds))
            defDim(ds,dimname,size(data,i))
        elseif !(dimname in unlimited(ds.dim))
            dimlen = dim(ds,dimname)

            if (dimlen != size(data,i))
                error("dimension $(dimname) is already defined with the " *
                    "length $dimlen. It cannot be redefined with a length of $(size(data,i)).")
            end
        end
    end

    T = eltype(data)
    attrib = collect(attrib)

    if T <: Union{TimeType,Missing}
        dattrib = Dict(attrib)
        if !haskey(dattrib,"units")
            push!(attrib,"units" => CFTime.DEFAULT_TIME_UNITS)
        end
        if !haskey(dattrib,"calendar")
            # these dates cannot be converted to the standard calendar
            if T <: Union{DateTime360Day,Missing}
                push!(attrib,"calendar" => "360_day")
            elseif T <: Union{DateTimeNoLeap,Missing}
                push!(attrib,"calendar" => "365_day")
            elseif T <: Union{DateTimeAllLeap,Missing}
                push!(attrib,"calendar" => "366_day")
            end
        end
    end

    v =
        if Missing <: T
            # make sure a fill value is set (it might be overwritten by kwargs...)
            defVar(ds,name,nctype,vardimnames;
                   fillvalue = fillvalue(nctype),
                   attrib = attrib,
                   kwargs...)
        else
            defVar(ds,name,nctype,vardimnames;
                   attrib = attrib,
                   kwargs...)
        end

    v[:] = data
    return v
end


function defVar(ds::AbstractDataset,name,data::T; kwargs...) where T <: Union{Number,String,Char}
    v = defVar(ds,name,T,(); kwargs...)
    v[:] = data
    return v
end

"""
    v = CommonDataModel.defVar(ds::AbstractDataset,src::AbstractVariable)

Defines and return the variable in the data set `ds`
copied from the variable `src`. The variable name, dimension name, attributes
and data are copied from `src`.
"""
function defVar(ds::AbstractDataset,src::AbstractVariable)
    v = defVar(ds,name(src),
               Array(src),
               dimnames(src),
               attrib=attribs(src))
    return v
end

"""
    ds = CommonDataModel.dataset(v::AbstractVariable)

Return the data set `ds` to which a the variable `v` belongs to.
"""
function dataset(v::AbstractVariable)
    error("unimplemented for abstract type")
end


function Base.show(io::IO,v::AbstractVariable)
    level = get(io, :level, 0)
    indent = " " ^ get(io, :level, 0)
    delim = " × "
    try
        dims = dimnames(v)
        sz = size(v)
        printstyled(io, indent, name(v),color=variable_color[])
        if length(sz) > 0
            print(io,indent," (",join(sz,delim),")\n")

            print(io,indent,"  Datatype:    ")
            printstyled(io,eltype(v),bold=true)
            if v isa CFVariable
                print(io," (",eltype(v.var),")")
            end
            print(io,"\n")
            print(io,indent,"  Dimensions:  ",join(dims,delim),"\n")
        else
            print(io,indent,"\n")
        end

        if length(v.attrib) > 0
            print(io,indent,"  Attributes:\n")
            show_attrib(IOContext(io,:level=>level+3),attribs(v))
        end
    catch err
        @debug "error in show" err
        print(io,"Variable (dataset closed)")
    end
end
