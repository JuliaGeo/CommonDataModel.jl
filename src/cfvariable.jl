"""
    sz = size(var::CFVariable)

Return a tuple of integers with the size of the variable `var`.

!!! note

    Note that the size of a variable can change, i.e. for a variable with an
    unlimited dimension.
"""
Base.size(v::CFVariable) = size(v.var)

name(v::CFVariable) = name(v.var)
dataset(v::CFVariable) = dataset(v.var)


attribnames(v::CFVariable) = keys(v.attrib)
attrib(v::CFVariable,name::SymbolOrString) = v.attrib[name]
defAttrib(v::CFVariable,name,value) = defAttrib(v.var,name,value)

dimnames(v::CFVariable) = dimnames(v.var)
dim(v::CFVariable,name::SymbolOrString) = dim(v.var,name)

# necessary for IJulia if showing a variable from a closed file
Base.show(io::IO,::MIME"text/plain",v::AbstractVariable) = show(io,v)

Base.display(v::AbstractVariable) = show(stdout,v)


"""
    v = cfvariable(ds::NCDataset,varname::SymbolOrString; <attrib> = <value>)

Return the variable `varname` in the dataset `ds` as a
`NCDataset.CFVariable`. The keyword argument `<attrib>` are
the attributes (`fillvalue`, `missing_value`, `scale_factor`, `add_offset`,
`units` and `calendar`) relevant to the CF conventions.
By specifing the value of these attributes, the one can override the value
specified in the data set. If the attribute is set to `nothing`, then
the attribute is not loaded and the corresponding transformation is ignored.
This function is similar to `ds[varname]` with the additional flexibility that
some variable attributes can be overridden.


Example:

```julia
NCDataset("foo.nc","c") do ds
  defVar(ds,"data",[10., 11., 12., 13.], ("time",), attrib = Dict(
      "add_offset" => 10.,
      "scale_factor" => 0.2))
end

# The stored (packed) valued are [0., 5., 10., 15.]
# since 0.2 .* [0., 5., 10., 15.] .+ 10 is [10., 11., 12., 13.]

ds = NCDataset("foo.nc");

@show ds["data"].var[:]
# returns [0., 5., 10., 15.]

@show cfvariable(ds,"data")[:]
# returns [10., 11., 12., 13.]

# neither add_offset nor scale_factor are applied
@show cfvariable(ds,"data", add_offset = nothing, scale_factor = nothing)[:]
# returns [0, 5, 10, 15]

# add_offset is applied but not scale_factor
@show cfvariable(ds,"data", scale_factor = nothing)[:]
# returns [10, 15, 20, 25]

# 0 is declared as the fill value (add_offset and scale_factor are applied as usual)
@show cfvariable(ds,"data", fillvalue = 0)[:]
# return [missing, 11., 12., 13.]

# Use the time units: days since 2000-01-01
@show cfvariable(ds,"data", units = "days since 2000-01-01")[:]
# returns [DateTime(2000,1,11), DateTime(2000,1,12), DateTime(2000,1,13), DateTime(2000,1,14)]

close(ds)
```
"""
function cfvariable(ds,
                    varname;
                    _v = variable(ds,varname),
                    attrib = _v.attrib,
                    # special case for bounds variable who inherit
                    # units and calendar from parent variables
                    _parentname = boundsParentVar(ds,varname),
                    fillvalue = get(attrib,"_FillValue",nothing),
                    # missing_value can be a vector
                    missing_value = get(attrib,"missing_value",eltype(_v)[]),
                    #valid_min = get(attrib,"valid_min",nothing),
                    #valid_max = get(attrib,"valid_max",nothing),
                    #valid_range = get(attrib,"valid_range",nothing),
                    scale_factor = get(attrib,"scale_factor",nothing),
                    add_offset = get(attrib,"add_offset",nothing),
                    # look also at parent if defined
                    units = _getattrib(ds,_v,_parentname,"units",nothing),
                    calendar = _getattrib(ds,_v,_parentname,"calendar",nothing),
                    )

    v = _v
    T = eltype(v)


    # sanity check
    if (T <: Number) && (
        (eltype(missing_value) <: AbstractChar) ||
            (eltype(missing_value) <: AbstractString))
        @warn "variable '$varname' has a numeric type but the corresponding " *
            "missing_value ($missing_value) is a character or string. " *
            "Comparing, e.g. an integer and a string (1 == \"1\") will always evaluate to false. " *
            "See the function CommonDataModel.cfvariable how to manually override the missing_value attribute."
    end

    time_origin = nothing
    time_factor = nothing

    if (units isa String) && occursin(" since ",units)
        if calendar == nothing
            calendar = "standard"
        elseif calendar isa String
            calendar = lowercase(calendar)
        end
        try
            time_origin,time_factor = CFTime.timeunits(units, calendar)
        catch err
            calendar = nothing
            @warn(sprint(showerror,err))
        end
    end

    scaledtype = T
    if eltype(v) <: Number
        if scale_factor !== nothing
            scaledtype = promote_type(scaledtype, typeof(scale_factor))
        end

        if add_offset !== nothing
            scaledtype = promote_type(scaledtype, typeof(add_offset))
        end
    end

    storage_attrib = (
        fillvalue = fillvalue,
        missing_values = (missing_value...,),
        scale_factor = scale_factor,
        add_offset = add_offset,
        calendar = calendar,
        time_origin = time_origin,
        time_factor = time_factor,
    )

    rettype = _get_rettype(ds, calendar, fillvalue, missing_value, scaledtype)

    return CFVariable{rettype,ndims(v),typeof(v),typeof(attrib),typeof(storage_attrib)}(
        v,attrib,storage_attrib)

end


function _get_rettype(ds, calendar, fillvalue, missing_value, rettype)
    # rettype can be a date if calendar is different from nothing
    if calendar !== nothing
        DT = nothing
        try
            DT = CFTime.timetype(calendar)
            # this is the only supported option for NCDatasets
            prefer_datetime = true

            if prefer_datetime &&
                (DT in (DateTimeStandard,DateTimeProlepticGregorian,DateTimeJulian))
                rettype = DateTime
            else
                rettype = DT
            end
        catch
            @warn("unsupported calendar `$calendar`. Time units are ignored.")
        end
    end

    if (fillvalue !== nothing) || (!isempty(missing_value))
        rettype = Union{Missing,rettype}
    end
    return rettype
end

fillvalue(v::CFVariable) = v._storage_attrib.fillvalue
missing_values(v::CFVariable) = v._storage_attrib.missing_values

# collect all possible fill values
function fill_and_missing_values(v::CFVariable)
    T = eltype(v.var)
    fv = ()
    if !isnothing(fillvalue(v))
        fv = (fillvalue(v),)
    end

    mv = missing_values(v)
    (fv...,mv...)
end

scale_factor(v::CFVariable) = v._storage_attrib.scale_factor
add_offset(v::CFVariable) = v._storage_attrib.add_offset
time_origin(v::CFVariable) = v._storage_attrib.time_origin
calendar(v::CFVariable) = v._storage_attrib.calendar

"""
    tf = CommonDataModel.time_factor(v::CFVariable)

The time unit in milliseconds. E.g. seconds would be 1000., days would be 86400000.
The result can also be `nothing` if the variable has no time units.
"""
time_factor(v::CFVariable) = v._storage_attrib[:time_factor]



# fillvalue can be NaN (unfortunately)
@inline isfillvalue(data,fillvalue) = data == fillvalue
@inline isfillvalue(data,fillvalue::AbstractFloat) = (isnan(fillvalue) ? isnan(data) : data == fillvalue)

# tuple peeling
@inline function CFtransform_missing(data,fv::Tuple)
    if isfillvalue(data,first(fv))
        missing
    else
        CFtransform_missing(data,Base.tail(fv))
    end
end

@inline CFtransform_missing(data,fv::Tuple{}) = data

@inline CFtransform_replace_missing(data,fv) = (ismissing(data) ? first(fv) : data)
@inline CFtransform_replace_missing(data,fv::Tuple{}) = data

@inline CFtransform_scale(data,scale_factor) = data*scale_factor
@inline CFtransform_scale(data,scale_factor::Nothing) = data
@inline CFtransform_scale(data::T,scale_factor) where T <: Union{Char,String} = data
@inline CFtransform_scale(data::T,scale_factor::Nothing) where T <: Union{Char,String} = data

@inline CFtransform_offset(data,add_offset) = data + add_offset
@inline CFtransform_offset(data,add_offset::Nothing) = data
@inline CFtransform_offset(data::T,add_factor) where T <: Union{Char,String} = data
@inline CFtransform_offset(data::T,add_factor::Nothing) where T <: Union{Char,String} = data


@inline asdate(data::Missing,time_origin,time_factor,DTcast) = data
@inline asdate(data,time_origin::Nothing,time_factor,DTcast) = data
@inline asdate(data::Missing,time_origin::Nothing,time_factor,DTcast) = data

@inline asdate(data,time_origin,time_factor,DTcast) =
    convert(DTcast,time_origin + Dates.Millisecond(round(Int64,time_factor * data)))

# special case when time variables are stored as single precision,
# promoted internally to double precision
@inline asdate(data::Float32,time_origin::Nothing,time_factor,DTcast) = data
@inline asdate(data::Float32,time_origin,time_factor,DTcast) =
    convert(DTcast,time_origin + Dates.Millisecond(round(Int64,time_factor * Float64(data))))


@inline fromdate(data::TimeType,time_origin,inv_time_factor) =
    Dates.value(data - time_origin) * inv_time_factor
@inline fromdate(data,time_origin,time_factor) = data

@inline function CFtransform(data,fv,scale_factor,add_offset,time_origin,time_factor,DTcast)
    return asdate(
        CFtransform_offset(
            CFtransform_scale(
                CFtransform_missing(data,fv),
                scale_factor),
            add_offset),
        time_origin,time_factor,DTcast)
end

# round float to integers
_approximate(::Type{T},data) where T <: Integer = round(T,data)
_approximate(::Type,data) = data


@inline function CFinvtransform(data,fv,inv_scale_factor,minus_offset,time_origin,inv_time_factor,DT)
    return _approximate(
        DT,
        CFtransform_replace_missing(
            CFtransform_scale(
                CFtransform_offset(
                    fromdate(data,time_origin,inv_time_factor),
                    minus_offset),
                inv_scale_factor),
            fv))
end


# this is really slow
# https://github.com/JuliaLang/julia/issues/28126
#@inline CFtransformdata(data,fv,scale_factor,add_offset,time_origin,time_factor,DTcast) =
#    # in boardcasting we trust..., or not
#    CFtransform.(data,fv,scale_factor,add_offset,time_origin,time_factor,DTcast)

# for scalars
@inline CFtransformdata(data,fv,scale_factor,add_offset,time_origin,time_factor,DTcast) =
    CFtransform(data,fv,scale_factor,add_offset,time_origin,time_factor,DTcast)

# in-place version
@inline function CFtransformdata!(out,data::AbstractArray{T,N},fv,scale_factor,add_offset,time_origin,time_factor) where {T,N}
    DTcast = eltype(out)
    @inbounds @simd for i in eachindex(data)
        out[i] = CFtransform(data[i],fv,scale_factor,add_offset,time_origin,time_factor,DTcast)
    end
    return out
end

# for arrays
@inline function CFtransformdata(data::AbstractArray{T,N},fv,scale_factor,add_offset,time_origin,time_factor,DTcast) where {T,N}
    out = Array{DTcast,N}(undef,size(data))
    return CFtransformdata!(out,data::AbstractArray{T,N},fv,scale_factor,add_offset,time_origin,time_factor)
end

@inline function CFtransformdata(
    data::AbstractArray{T,N},fv::Tuple{},scale_factor::Nothing,
    add_offset::Nothing,time_origin::Nothing,time_factor::Nothing,::Type{T}) where {T,N}
    # no transformation necessary (avoid allocation)
    return data
end

@inline _inv(x::Nothing) = nothing
@inline _inv(x) = 1/x
@inline _minus(x::Nothing) = nothing
@inline _minus(x) = -x


# # so slow
# @inline function CFinvtransformdata(data,fv,scale_factor,add_offset,time_origin,time_factor,DT)
#     inv_scale_factor = _inv(scale_factor)
#     minus_offset = _minus(add_offset)
#     inv_time_factor = _inv(time_factor)
#     return CFinvtransform.(data,fv,inv_scale_factor,minus_offset,time_origin,inv_time_factor,DT)
# end

# for arrays
@inline function CFinvtransformdata(data::AbstractArray{T,N},fv,scale_factor,add_offset,time_origin,time_factor,DT) where {T,N}
    inv_scale_factor = _inv(scale_factor)
    minus_offset = _minus(add_offset)
    inv_time_factor = _inv(time_factor)

    out = Array{DT,N}(undef,size(data))
    @inbounds @simd for i in eachindex(data)
        out[i] = CFinvtransform(data[i],fv,inv_scale_factor,minus_offset,time_origin,inv_time_factor,DT)
    end
    return out
end

@inline function CFinvtransformdata(
    data::AbstractArray{T,N},fv::Tuple{},scale_factor::Nothing,
    add_offset::Nothing,time_origin::Nothing,time_factor::Nothing,::Type{T}) where {T,N}
    # no transformation necessary (avoid allocation)
    return data
end

# for scalar
@inline function CFinvtransformdata(data,fv,scale_factor,add_offset,time_origin,time_factor,DT)
    inv_scale_factor = _inv(scale_factor)
    minus_offset = _minus(add_offset)
    inv_time_factor = _inv(time_factor)

    return CFinvtransform(data,fv,inv_scale_factor,minus_offset,time_origin,inv_time_factor,DT)
end



# this function is necessary to avoid "iterating" over a single character in Julia 1.0 (fixed Julia 1.3)
# https://discourse.julialang.org/t/broadcasting-and-single-characters/16836
@inline CFtransformdata(data::Char,fv,scale_factor,add_offset,time_origin,time_factor,DTcast) = CFtransform_missing(data,fv)
@inline CFinvtransformdata(data::Char,fv,scale_factor,add_offset,time_origin,time_factor,DT) = CFtransform_replace_missing(data,fv)


function Base.getindex(v::CFVariable, indexes::Union{Integer,Colon,AbstractRange{<:Integer},AbstractVector{<:Integer}}...)
    data = v.var[indexes...]
    return CFtransformdata(data,fill_and_missing_values(v),scale_factor(v),add_offset(v),
                           time_origin(v),time_factor(v),eltype(v))
end

function Base.setindex!(v::CFVariable,data::Array{Missing,N},indexes::Union{Int,Colon,AbstractRange{<:Integer}}...) where N
    v.var[indexes...] = fill(fillvalue(v),size(data))
end

function Base.setindex!(v::CFVariable,data::Missing,indexes::Union{Int,Colon,AbstractRange{<:Integer}}...)
    v.var[indexes...] = fillvalue(v)
end

function Base.setindex!(v::CFVariable,data::Union{T,Array{T,N}},indexes::Union{Int,Colon,AbstractRange{<:Integer}}...) where N where T <: Union{AbstractCFDateTime,DateTime,Union{Missing,DateTime,AbstractCFDateTime}}

    if calendar(v) !== nothing
        # can throw an convertion error if calendar attribute already exists and
        # is incompatible with the provided data
        v.var[indexes...] = CFinvtransformdata(
            data,fill_and_missing_values(v),scale_factor(v),add_offset(v),
            time_origin(v),time_factor(v),eltype(v.var))
        return data
    end

    @error "Time units and calendar must be defined during defVar and cannot change"
end


function Base.setindex!(v::CFVariable,data,indexes::Union{Int,Colon,AbstractRange{<:Integer}}...)
    v.var[indexes...] = CFinvtransformdata(
        data,fill_and_missing_values(v),
        scale_factor(v),add_offset(v),
        time_origin(v),time_factor(v),eltype(v.var))

    return data
end


# can be implemented overridden for faster implementation
function boundsParentVar(ds,varname)
    for vn in varnames(ds)
        v = variable(ds,vn)
        bounds = get(attribs(v),"bounds","")
        if bounds === varname
            return vn
        end
    end

    return ""
end


"""
    _getattrib(ds,v,parentname,attribname,default)

Get an attribute, looking also at the parent variable name
(linked via the bounds attribute as following the CF conventions).
The default value is returned if the attribute cannot be found.
"""
function _getattrib(ds,v,parentname,attribname,default)
    val = get(v.attrib,attribname,nothing)
    if val !== nothing
        return val
    else
        if (parentname === nothing) || (parentname === "")
            return default
        else
            vp = variable(ds,parentname)
            return get(vp.attrib,attribname,default)
        end
    end
end



function _isrelated(v1::AbstractVariable,v2::AbstractVariable)
    dimnames(v1) ⊆ dimnames(v2)
end

function Base.keys(v::AbstractVariable)
    ds = dataset(v)
    return [varname for (varname,ncvar) in ds if _isrelated(ncvar,v)]
end


function Base.getindex(v::AbstractVariable,name::SymbolOrString)
    ds = dataset(v)
    ncvar = ds[name]
    if _isrelated(ncvar,v)
        return ncvar
    else
        throw(KeyError(name))
    end
end

Base.getindex(v::CFVariable,n::CFStdName) = getindex_byname(v,n)



"""
    dimnames(v::CFVariable)

Return a tuple of strings with the dimension names of the variable `v`.
"""
dimnames(v::Union{CFVariable,MFCFVariable})  = dimnames(v.var)

name(v::Union{CFVariable,MFCFVariable}) = name(v.var)
chunking(v::CFVariable,storage,chunksize) = chunking(v.var,storage,chunksize)
chunking(v::CFVariable) = chunking(v.var)

deflate(v::CFVariable,shuffle,dodeflate,deflate_level) = deflate(v.var,shuffle,dodeflate,deflate_level)
deflate(v::CFVariable) = deflate(v.var)

checksum(v::CFVariable,checksummethod) = checksum(v.var,checksummethod)
checksum(v::CFVariable) = checksum(v.var)


fillmode(v::CFVariable) = fillmode(v.var)




# indexing with vector of integers

to_range_list(index::Integer,len) = index

to_range_list(index::Colon,len) = [1:len]
to_range_list(index::AbstractRange,len) = [index]

function to_range_list(index::Vector{T},len) where T <: Integer
    grow(istart) = istart[begin]:(istart[end]+step(istart))

    baseindex = 1
    indices_ranges = UnitRange{T}[]

    while baseindex <= length(index)
        range = index[baseindex]:index[baseindex]
        range_test = grow(range)
        index_view = @view index[baseindex:end]

        while checkbounds(Bool,index_view,length(range_test)) &&
            (range_test[end] == index_view[length(range_test)])

            range = range_test
            range_test = grow(range_test)
        end

        push!(indices_ranges,range)
        baseindex += length(range)
    end

    @assert reduce(vcat,indices_ranges,init=T[]) == index
    return indices_ranges
end

_range_indices_dest(of) = of
_range_indices_dest(of,i::Integer,rest...) = _range_indices_dest(of,rest...)

function _range_indices_dest(of,v,rest...)
    b = 0
    ind = similar(v,0)
    for r in v
        rr = 1:length(r)
        push!(ind,b .+ rr)
        b += length(r)
    end

    _range_indices_dest((of...,ind),rest...)
end
range_indices_dest(ri...) = _range_indices_dest((),ri...)

function Base.getindex(v::Union{MFVariable,SubVariable},indices::Union{Int,Colon,AbstractRange{<:Integer},Vector{Int}}...)
    @debug "transform vector of indices to ranges"

    sz_source = size(v)
    ri = to_range_list.(indices,sz_source)
    sz_dest = _shape_after_slice(sz_source,indices...)

    N = length(indices)

    ri_dest = range_indices_dest(ri...)
    @debug "ri_dest $ri_dest"
    @debug "ri $ri"

    if all(==(1),length.(ri))
        # single chunk
        R = first(CartesianIndices(length.(ri)))
        ind_source = ntuple(i -> ri[i][R[i]],N)
        ind_dest = ntuple(i -> ri_dest[i][R[i]],length(ri_dest))
        return v[ind_source...]
    end

    dest = Array{eltype(v),length(sz_dest)}(undef,sz_dest)
    for R in CartesianIndices(length.(ri))
        ind_source = ntuple(i -> ri[i][R[i]],N)
        ind_dest = ntuple(i -> ri_dest[i][R[i]],length(ri_dest))
        #dest[ind_dest...] = v[ind_source...]
        if hasproperty(v,:var)
            buffer = Array{eltype(v.var),length(ind_dest)}(undef,length.(ind_dest))
            load!(v,view(dest,ind_dest...),buffer,ind_source...)
        else
            dest[ind_dest...] = v[ind_source...]
        end
    end
    return dest
end


############################################################
# Convertion to array
############################################################

Base.Array(v::AbstractVariable{T,N}) where {T,N} = v[ntuple(i -> :, Val(N))...]


"""
    CommonDataModel.load!(ncvar::CFVariable, data, buffer, indices)

Loads a NetCDF (or other format) variables `ncvar` in-place and puts the result in `data` (an
array of `eltype(ncvar)`) along the specified `indices`. `buffer` is a temporary
 array of the same size as data but the type should be `eltype(ncv.var)`, i.e.
the corresponding type in the files (before applying `scale_factor`,
`add_offset` and masking fill values). Scaling and masking will be applied to
the array `data`.

`data` and `buffer` can be the same array if `eltype(ncvar) == eltype(ncvar.var)`.

## Example:

```julia
# create some test array
Dataset("file.nc","c") do ds
    defDim(ds,"time",3)
    ncvar = defVar(ds,"vgos",Int16,("time",),attrib = ["scale_factor" => 0.1])
    ncvar[:] = [1.1, 1.2, 1.3]
    # store 11, 12 and 13 as scale_factor is 0.1
end


ds = Dataset("file.nc")
ncv = ds["vgos"];
# data and buffer must have the right shape and type
data = zeros(eltype(ncv),size(ncv)); # here Vector{Float64}
buffer = zeros(eltype(ncv.var),size(ncv)); # here Vector{Int16}
NCDatasets.load!(ncv,data,buffer,:,:,:)
close(ds)
```
"""
@inline function load!(v::Union{CFVariable{T,N},MFCFVariable{T,N},SubVariable{T,N}}, data, buffer, indices::Union{Integer, AbstractRange{<:Integer}, Colon}...) where {T,N}

    if v.var == nothing
        return load!(v,indices...)
    else
        load!(v.var,buffer,indices...)
        fmv = fill_and_missing_values(v)
        return CFtransformdata!(data,buffer,fmv,scale_factor(v),add_offset(v),
                                time_origin(v),time_factor(v))
    end
end
