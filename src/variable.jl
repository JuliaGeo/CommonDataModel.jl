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

"""
    fillvalue(::Type{Int8})
    fillvalue(::Type{UInt8})
    fillvalue(::Type{Int16})
    fillvalue(::Type{UInt16})
    fillvalue(::Type{Int32})
    fillvalue(::Type{UInt32})
    fillvalue(::Type{Int64})
    fillvalue(::Type{UInt64})
    fillvalue(::Type{Float32})
    fillvalue(::Type{Float64})
    fillvalue(::Type{Char})
    fillvalue(::Type{String})

Default fill-value for the given type from NetCDF.
"""
@inline fillvalue(::Type{Int8})    = Int8(-127)
@inline fillvalue(::Type{UInt8})   = UInt8(255)
@inline fillvalue(::Type{Int16})   = Int16(-32767)
@inline fillvalue(::Type{UInt16})  = UInt16(65535)
@inline fillvalue(::Type{Int32})   = Int32(-2147483647)
@inline fillvalue(::Type{UInt32})  = UInt32(4294967295)
@inline fillvalue(::Type{Int64})   = Int64(-9223372036854775806)
@inline fillvalue(::Type{UInt64})  = UInt64(18446744073709551614)
@inline fillvalue(::Type{Float32}) = 9.9692099683868690f+36
@inline fillvalue(::Type{Float64}) = 9.9692099683868690e+36
@inline fillvalue(::Type{Char})    = '\0'
@inline fillvalue(::Type{String})  = ""



# convert e.g. Union{Float64,Missing} to Float64
# similar to Base.nonmissingtype
_nonuniontype(::Type{T},::Type{Union{T,S}}) where {T,S} = S
function nonuniontype(T,TS)
    if typeof(TS) == Union
        _nonuniontype(T,TS)
    else
        TS
    end
end

function defVar(ds::AbstractDataset,
                name::SymbolOrString,
                data::AbstractArray{T,N},
                dimnames;
                kwargs...) where {T,N}

    Tmaskingvalue = typeof(maskingvalue(ds))

    # convert e.g. Union{Float64,Missing} or Union{Float64,Nothing} to Float64
    nctype = nonuniontype(Tmaskingvalue,T)
    _defVar(ds,name,data,nctype,dimnames; kwargs...)
end

# defining a scalar
function defVar(ds::AbstractDataset,name::SymbolOrString,data,dimnames; kwargs...)
    # eltype of a String would be Char
    if data isa String
        nctype = String
    else
        nctype = eltype(data)
    end
    _defVar(ds,name,data,nctype,dimnames; kwargs...)
end


as_dict(x::NamedTuple) = OrderedDict(zip(keys(x),values(x)))
as_dict(x) = OrderedDict(x)

function _defVar(ds::AbstractDataset,name::SymbolOrString,data,::Type{<:Union{DateTime,AbstractCFDateTime}},vardimnames; kwargs...)
    _defVar(ds,name,data,Float64,vardimnames; kwargs...)
end

function _defVar(ds::AbstractDataset,name::SymbolOrString,data,nctype,vardimnames; attrib = [], kwargs...)

    # define the dimensions if necessary
    for (i,dimname) in enumerate(String.(vardimnames))
        if !(dimname in dimnames(ds))
            @debug "define dimension" dimname dimnames(ds)
            defDim(ds,dimname,size(data,i))
        elseif !(dimname in unlimited(ds))
            dimlen = dim(ds,dimname)

            if (dimlen != size(data,i))
                error("dimension $(dimname) is already defined with the " *
                    "length $dimlen. It cannot be redefined with a length of $(size(data,i)).")
            end
        end
    end

    T = eltype(data)
    Tmaskingvalue = typeof(maskingvalue(ds))

    # we should preserve the order
    # value type is promoted to Any as we add values of different type
    attrib = convert(OrderedDict{SymbolOrString,Any},as_dict(attrib))

    Tnonunion = nonuniontype(Tmaskingvalue,T)
    if Tnonunion <: TimeType
        if !haskey(attrib,"units")
            push!(attrib,"units" => CFTime.DEFAULT_TIME_UNITS)
        end
        if !haskey(attrib,"calendar")
            # these dates cannot be converted to the standard calendar
            if T <: Union{DateTime360Day,Tmaskingvalue}
                push!(attrib,"calendar" => "360_day")
            elseif T <: Union{DateTimeNoLeap,Tmaskingvalue}
                push!(attrib,"calendar" => "365_day")
            elseif T <: Union{DateTimeAllLeap,Tmaskingvalue}
                push!(attrib,"calendar" => "366_day")
            end
        end
    end

    # make sure a fill value is set
    if (Tmaskingvalue <: T) && !haskey(attrib,"_FillValue") &&
        !haskey(kwargs,:fillvalue)
        push!(attrib,"_FillValue" => fillvalue(nctype))
    end

    v = defVar(ds,name,nctype,vardimnames;
                   attrib = attrib,
                   kwargs...)

    # "v[:] = data" does not work with DiskArrays and unlimited dimensions
    if data isa String
        # axes of a scalar String fails (while ok for Number and Char)
        v[] = data
    else
        v[axes(data)...] = data
    end
    return v
end


# dimension names can be ommited for scalars
function defVar(ds::AbstractDataset,name,data::T; kwargs...) where T <: Union{Number,String,Char}
    v = defVar(ds,name,T,(); kwargs...)
    v[] = data
    return v
end

"""
    v = CommonDataModel.defVar(ds::AbstractDataset,src::AbstractVariable)
    v = CommonDataModel.defVar(ds::AbstractDataset,name::SymbolOrString,src::AbstractVariable)

Defines and return the variable in the data set `ds`
copied from the variable `src`. The dimension name, attributes
and data are copied from `src` as well as the variable name (unless provide by `name`).
"""
function defVar(dest::AbstractDataset,name::SymbolOrString,srcvar::AbstractVariable; kwargs...)
    v = defVar(dest,name,
               Array(srcvar),
               dimnames(srcvar),
               attrib=attribs(srcvar); kwargs...)
    return v
end

function defVar(dest::AbstractDataset,srcvar::AbstractVariable; kwargs...)
    defVar(dest,name(srcvar),srcvar; kwargs...)
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



chunking(v::AbstractVariable) = (:contiguous,size(v))
deflate(v::AbstractVariable) = (false,false,0)
checksum(v::AbstractVariable) = :nochecksum

fillvalue(v::AbstractVariable{T}) where T = v.attrib["_FillValue"]::T


# computes the shape of the array of size `sz` after applying the indexes
# size(a[indexes...]) == _shape_after_slice(size(a),indexes...)

# the difficulty here is to make the size inferrable by the compiler
@inline _shape_after_slice(sz,indexes...) = __sh(sz,(),1,indexes...)
@inline __sh(sz,sh,n,i::Integer,indexes...) = __sh(sz,sh,               n+1,indexes...)
@inline __sh(sz,sh,n,i::Colon,  indexes...) = __sh(sz,(sh...,sz[n]),    n+1,indexes...)
@inline __sh(sz,sh,n,i,         indexes...) = __sh(sz,(sh...,length(i)),n+1,indexes...)
@inline __sh(sz,sh,n) = sh
