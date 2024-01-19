
attribnames(ds::MFDataset) = attribnames(ds.ds[1])

attrib(ds::MFDataset,name::SymbolOrString) = attrib(ds.ds[1],name)

attribnames(v::Union{MFCFVariable,MFVariable}) = attribnames(variable(v.ds.ds[1],v.varname))

attrib(v::Union{MFCFVariable,MFVariable},name::SymbolOrString) = attrib(variable(v.ds.ds[1],v.varname),name)

function defAttrib(v::Union{MFCFVariable,MFVariable},name::SymbolOrString,data)
    for ds in v.ds.ds
        defAttrib(variable(v.ds,v.varname),name,data)
    end
    return data
end

function defAttrib(ds::MFDataset,name::SymbolOrString,data)
    for _ds in ds.ds
        defAttrib(_ds,name,data)
    end
    return data
end

function dim(ds::MFDataset,name::SymbolOrString)
    if name == ds.aggdim
        if ds.isnewdim
            return length(ds.ds)
        else
            return sum(dim(_ds,name) for _ds in ds.ds)
        end
    else
        return dim(ds.ds[1],name)
    end
end

function defDim(ds::MFDataset,name::SymbolOrString,data)
    for _ds in ds.ds
        defDim(_ds,name,data)
    end
    return data
end

function dimnames(ds::MFDataset)
    k = collect(dimnames(ds.ds[1]))

    if ds.isnewdim
        push!(k,ds.aggdim)
    end

    return k
end

unlimited(ds::MFDataset) = unique(reduce(hcat,unlimited.(ds.ds)))

groupnames(ds::MFDataset) = groupnames(ds.ds[1])

function group(mfds::MFDataset,name::SymbolOrString)
    ds = group.(mfds.ds,name)
    constvars = Symbol[]
    return MFDataset(ds,mfds.aggdim,mfds.isnewdim,constvars)
end

function parentdataset(mfds::MFDataset)
    ds = parentdataset.(mfds.ds)
    return MFDataset(ds,mfds.aggdim,mfds.isnewdim,mfds.constvars)
end

Base.Array(v::MFVariable) = Array(v.var)

iswritable(mfds::MFDataset) = iswritable(mfds.ds[1])

function MFDataset(ds,aggdim,isnewdim,constvars)
    _boundsmap = Dict{String,String}()
    mfds = MFDataset(ds,aggdim,isnewdim,constvars,_boundsmap)
    if !iswritable(mfds)
        initboundsmap!(mfds)
    end
    return mfds
end


function MFDataset(TDS,fnames::AbstractArray{<:AbstractString,N},mode = "r"; aggdim = nothing,
                   deferopen = true,
                   _aggdimconstant = false,
                   isnewdim = false,
                   constvars = Union{Symbol,String}[],
                   ) where N
    if !(mode == "r" || mode == "a")
        throw(ArgumentError("""Unsupported mode for multi-file dataset (mode = $(mode)). Mode must be "r" or "a"."""))
    end

    if deferopen
        @assert mode == "r"

        if _aggdimconstant
            # load only metadata from master
            master_index = 1
            ds_master = TDS(fnames[master_index],mode);
            data_master = metadata(ds_master)
            ds = Vector{Union{TDS,DeferDataset}}(undef,length(fnames))
            #ds[master_index] = ds_master
            for (i,fname) in enumerate(fnames)
                #if i !== master_index
                ds[i] = DeferDataset(TDS,fname,mode,data_master)
                #end
            end
        else
            ds = DeferDataset.(TDS,fnames,mode)
        end
    else
        ds = TDS.(fnames,mode);
    end

    if (aggdim == nothing) && !isnewdim
        # first unlimited dimensions
        aggdim = unlimited(ds[1].dim)[1]
    end

    mfds = MFDataset(ds,aggdim,isnewdim,Symbol.(constvars))
    return mfds
end


Base.getindex(v::Union{MFVariable,DeferVariable},ci::CartesianIndices) = v[ci.indices...]
Base.setindex!(v::Union{MFVariable,DeferVariable},data,ci::CartesianIndices) = setindex!(v,data,ci.indices...)



function close(mfds::MFDataset)
    close.(mfds.ds)
    return nothing
end

function sync(mfds::MFDataset)
    sync.(mfds.ds)
    return nothing
end

function path(mfds::MFDataset)
    path(mfds.ds[1]) * "…" * path(mfds.ds[end])
end

name(mfds::MFDataset) = name(mfds.ds[1])
# to depreciate?
groupname(mfds::MFDataset) = name(mfds.ds[1])

function Base.keys(mfds::MFDataset)
    if mfds.aggdim == ""
        return unique(Iterators.flatten(keys.(mfds.ds)))
    else
        keys(mfds.ds[1])
    end
end

Base.getindex(v::MFVariable,indexes::Union{Int,Colon,AbstractRange{<:Integer}}...) = getindex(v.var,indexes...)
Base.setindex!(v::MFVariable,data,indexes::Union{Int,Colon,AbstractRange{<:Integer}}...) = setindex!(v.var,data,indexes...)

Base.size(v::MFVariable) = size(v.var)
Base.size(v::MFCFVariable) = size(v.var)
dimnames(v::MFVariable) = v.dimnames
name(v::MFVariable) = v.varname


function variable(mfds::MFDataset,varname::SymbolOrString)
    if mfds.isnewdim
        if Symbol(varname) in mfds.constvars
            return variable(mfds.ds[1],varname)
        end
        # aggregated along a given dimension
        vars = variable.(mfds.ds,varname)
        v = CatArrays.CatArray(ndims(vars[1])+1,vars...)
        return MFVariable(mfds,v,
                          (dimnames(vars[1])...,mfds.aggdim),String(varname))
    elseif mfds.aggdim == ""
        # merge all variables

        # the latest dataset should be used if a variable name is present multiple times
        for ds in reverse(mfds.ds)
            if haskey(ds,varname)
                return variable(ds,varname)
            end
        end
    else
        # aggregated along a given dimension
        vars = variable.(mfds.ds,varname)

        dim = findfirst(dimnames(vars[1]) .== mfds.aggdim)
        @debug "dimension $dim"

        if (dim != nothing)
            v = CatArrays.CatArray(dim,vars...)
            return MFVariable(mfds,v,
                          dimnames(vars[1]),String(varname))
        else
            return vars[1]
        end
    end
end

function cfvariable(mfds::MFDataset,varname::SymbolOrString)
    if mfds.isnewdim
        if Symbol(varname) in mfds.constvars
            return cfvariable(mfds.ds[1],varname)
        end
        # aggregated along a given dimension
        cfvars = cfvariable.(mfds.ds,varname)
        cfvar = CatArrays.CatArray(ndims(cfvars[1])+1,cfvars...)
        var = variable(mfds,varname)

        return MFCFVariable(mfds,cfvar,var,
                            dimnames(var),varname)
    elseif mfds.aggdim == ""
        # merge all variables

        # the latest dataset should be used if a variable name is present multiple times
        for ds in reverse(mfds.ds)
            if haskey(ds,varname)
                return cfvariable(ds,varname)
            end
        end
    else
        # aggregated along a given dimension
        cfvars = cfvariable.(mfds.ds,varname)

        dim = findfirst(dimnames(cfvars[1]) .== mfds.aggdim)
        @debug "dim $dim"

        if (dim != nothing)
            cfvar = CatArrays.CatArray(dim,cfvars...)
            var = variable(mfds,varname)

            return MFCFVariable(mfds,cfvar,var,
                          dimnames(var),String(varname))
        else
            return cfvars[1]
        end
    end
end


dataset(v::Union{MFVariable,MFCFVariable}) = v.ds


Base.getindex(v::MFCFVariable,ind...) = v.cfvar[ind...]
Base.setindex!(v::MFCFVariable,data,ind...) = v.cfvar[ind...] = data


function Base.cat(vs::AbstractVariable...; dims::Integer)
    CatArrays.CatArray(dims,vs...)
end

"""
    storage,chunksizes = chunking(v::MFVariable)
    storage,chunksizes = chunking(v::MFCFVariable)

Return the storage type (`:contiguous` or `:chunked`) and the chunk sizes of the varable
`v` corresponding to the first file. If the first file in the collection
is chunked then this storage attributes are returned. If not the first file is not contiguous, then multi-file variable is still reported as chunked with chunk size equal to the size of the first variable.
"""
function chunking(v::MFVariable)
    v1 = v.ds.ds[1][name(v)]
    storage,chunksizes = chunking(v1)

    if storage == :contiguous
        return (:chunked, size(v1))
    else
        return storage,chunksizes
    end
end

deflate(v::MFVariable) = deflate(v.ds.ds[1][name(v)])
checksum(v::MFVariable) = checksum(v.ds.ds[1][name(v)])

chunking(v::MFCFVariable) = chunking(v.var)
deflate(v::MFCFVariable) = deflate(v.var)
checksum(v::MFCFVariable) = checksum(v.var)
