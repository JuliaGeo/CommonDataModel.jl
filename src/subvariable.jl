
function Base.show(io::IO, v::SubVariable)
    level = get(io, :level, 0)
    indent = " " ^ get(io, :level, 0)
    delim = " × "
    try
        indices = parentindices(v)
        print(io,indent,"View:  ",join(indices,delim),"\n")
        show(IOContext(io,:level=>level+1),parent(v))
    catch err
        @warn "error in show" err
        print(io,"SubVariable (dataset closed)")
    end
end

Base.show(io::IO,::MIME"text/plain",v::SubVariable) = show(io,v)

DiskArrays.subarray(v::SubVariable) = v.v

function Base.getproperty(sub_var::SubVariable, name::Symbol)
    if !hasfield(typeof(sub_var),name)
        parent_var = parent(sub_var)
        if name == :var
            # if var also return a view
            return view(parent_var.var, sub_indices(sub_var)...)
        else
            return Base.getproperty(parent_var, name)
        end
    else
        return getfield(sub_var,name) # get field from sub_var
    end 
end

function dimnames(v::SubVariable)
    dimension_names = dimnames(parent(v))
    return dimension_names[map(i -> !(i isa Integer),collect(parentindices(v)))]
end

name(v::SubVariable) = name(parent(v))

attribnames(v::SubVariable) = attribnames(parent(v))
attrib(v::SubVariable,name::SymbolOrString) = attrib(parent(v),name)
defAttrib(v::SubVariable,name::SymbolOrString,data) = defAttrib(parent(v),name,data)
materialize(v::SubVariable) = parent(v)[sub_indices(v)]
sub_indices(v::SubVariable) = DiskArrays.subarray(v).indices

function map_indices(parent_var::AbstractVariable, selected_var::AbstractVariable,
         indices_subvariable)
    
    dims_selected = dimnames(selected_var)
    dims_var= dimnames(parent_var)
    dim_mapping = [findfirst( x-> x==d, dims_var) for d in dims_selected]

    indices_selected = indices_subvariable[dim_mapping]
    return indices_selected
end


## getting the related var also returns a SubVariable
function Base.getindex(sub_var::SubVariable,n::Union{CFStdName,SymbolOrString})
    parent_var = parent(sub_var)
    selected_var = parent_var[n]

    indices_selected = map_indices(parent_var, selected_var, sub_indices(sub_var))
    return view(selected_var, indices_selected...)
end

"""
    sv = view(v::CommonDataModel.AbstractVariable,indices...)

Returns a view of the variable `v` where indices are only lazily applied.
No data is actually copied or loaded.
Modifications to a view `sv`, also modifies the underlying array `v`.
All attributes of `v` are also present in `sv`.

# Examples

```julia
using NCDatasets
fname = tempname()
data = zeros(Int,10,11)
ds = NCDataset(fname,"c")
ncdata = defVar(ds,"temp",data,("lon","lat"))
ncdata_view = view(ncdata,2:3,2:4)
size(ncdata_view)
# output (2,3)
ncdata_view[1,1] = 1
ncdata[2,2]
# outputs 1 as ncdata is also modified
close(ds)
```

"""
function Base.view(a::AbstractVariable,i...) 
    disk_sub_array = DiskArrays.view_disk(a, i...)
    return SubVariable(DiskArrays.subarray(disk_sub_array))
end

Base.vec(a::AbstractVariable) = view(a, :)

dimnames(ds::SubDataset) = dimnames(ds.ds)
defDim(ds::SubDataset,name::SymbolOrString,len) = defDim(ds.ds,name,len)


function dim(ds::SubDataset,dimname::SymbolOrString)
    dn = Symbol(dimname)
    if hasproperty(ds.indices,dn)
        ind = getproperty(ds.indices,dn)
        if ind == Colon()
            return ds.ds.dim[dimname]
        else
            return length(ind)
        end
    else
        return ds.ds.dim[dimname]
    end
end

unlimited(ds::SubDataset) = unlimited(ds.ds)


function SubDataset(ds::AbstractDataset,indices)
    group = OrderedDict((n => SubDataset(g,indices) for (n,g) in ds.group)...)
    SubDataset(ds,indices,ds.attrib,group)
end

function Base.view(ds::AbstractDataset; indices...)
    SubDataset(ds,values(indices))
end

function Base.getindex(ds::SubDataset,varname::Union{AbstractString, Symbol})
    ncvar = ds.ds[varname]
    if ndims(ncvar) == 0
        return ncvar
    end

    dims = dimnames(ncvar)
    ind = ntuple(i -> get(ds.indices,Symbol(dims[i]),:),ndims(ncvar))
    return view(ncvar,ind...)
end

function variable(ds::SubDataset,varname::Union{AbstractString, Symbol})
    ncvar = variable(ds.ds,varname)
    if ndims(ncvar) == 0
        return ncvar
    end
    dims = dimnames(ncvar)
    ind = ntuple(i -> get(ds.indices,Symbol(dims[i]),:),ndims(ncvar))
    return view(ncvar,ind...)
end


varnames(ds::SubDataset) = keys(ds.ds)
path(ds::SubDataset) = path(ds.ds)
groupname(ds::SubDataset) = groupname(ds.ds)


function dataset(v::SubVariable)
    indices = (;((Symbol(d),i) for (d,i) in zip(dimnames(parent(v)), sub_indices(v)))...)
    return SubDataset(dataset(parent(v)),indices)
end

function chunking(v::SubVariable)
    storage, chunksizes = chunking(parent(v))
    return storage, min.(chunksizes,size(v))
end

deflate(v::SubVariable) = deflate(parent(v))
checksum(v::SubVariable) = checksum(parent(v))
