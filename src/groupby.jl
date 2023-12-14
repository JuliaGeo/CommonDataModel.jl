
_indices_helper(j,ku,i,val) = ()
_indices_helper(j,ku,i,val,ind1::Integer,indices...) = _indices_helper(j,ku,i+1,val,indices...)
_indices_helper(j,ku,i,val,ind1,indices...) = ((i == j ? ku : val), _indices_helper(j,ku,i+1,val,indices...)...)


# _indices(j,ku,val,indices) produces a tuple with val for every dimension
# except `ku` for the the `j` dimension for an array A after subsetting it as
# `A[indices]`.

_indices(j,ku,val,indices) = _indices_helper(j,ku,1,val,indices...)
_dest_indices(j,ku,indices) = _indices_helper(j,ku,1,:,indices...)


@inline size_getindex(array,indexes...) = _size_getindex(array,(),1,indexes...)
@inline _size_getindex(array,sh,n,i::Integer,indexes...) = _size_getindex(array,sh,                   n+1,indexes...)
@inline _size_getindex(array::AbstractArray,sh,n,i::Colon,  indexes...) = _size_getindex(array,(sh...,size(array,n)),n+1,indexes...)
@inline _size_getindex(sz::Tuple,sh,n,i::Colon,  indexes...) = _size_getindex(sz,(sh...,sz[n]),n+1,indexes...)
@inline _size_getindex(array,sh,n,i,         indexes...) = _size_getindex(array,(sh...,length(i)),    n+1,indexes...)
@inline _size_getindex(array,sh,n) = sh

struct GroupedDataset{TDS,TF,TClass,TM,TRF} <: AbstractDataset
    ds::TDS # dataset
    coordname::Symbol
    group_fun::TF # mapping function
    class::Vector{TClass}
    unique_class::Vector{TClass}
    map_fun::TM
    reduce_fun::TRF
end

struct GroupedVariable{TV,TF,TClass,TM,TG} <: AbstractVector{TG} where TV <: AbstractArray{T,N} where {T,N}
    v::TV # dataset
    coordname::Symbol
    group_fun::TF # mapping function
    class::Vector{TClass}
    unique_class::Vector{TClass}
    dim::Int
    map_fun::TM
end

function Base.show(io::IO,::MIME"text/plain",gv::GroupedVariable)
    println(io,length(gv),"-element ",
            "variable grouped by '",gv.coordname,"'",
            " of array '",name(gv.v),"' ",
            join(string.(size(gv.v)),"×"),
            " (",
            join(dimnames(gv.v),"×"),
            ")",
            )
end

Base.show(io::IO,gv::GroupedVariable) = Base.show(io,MIME"text/plain",gv)

# reduce_fun is e.g. sum, mean, var,...
# map_fun is the mapping function applied before reduction
struct GroupedVariableResult{T,N,TGV,TF}  <: AbstractVariable{T,N}
    gv::TGV
    reduce_fun::TF
end

function Base.show(io::IO,::MIME"text/plain",gv::GroupedVariableResult)
    println(
        io,join(string.(size(gv)),'×')," array after reducing using ",
        "$(gv.reduce_fun)")
end

Base.ndims(gv::GroupedVariable) = 1
Base.size(gv::GroupedVariable) = (length(gv.unique_class),)
Base.eltype(gv::GroupedVariable{TV,TF,TClass,TM,TG}) where {TV,TF,TClass,TM,TG} = TG

function group(gv::GroupedVariable,k::Integer)
    class_k = gv.unique_class[k]
    indices = findall(==(class_k),gv.class)
    return class_k, indices
end

function Base.getindex(gv::GroupedVariable,k::Integer)
    class_k,indices = group(gv,k)
    return gv.map_fun(Array(selectdim(gv.v,gv.dim,indices)))
end


# Types like Dates.Month behave different than normal scalars, e.g.
# julia> length(Dates.Month(1))
# ERROR: MethodError: no method matching length(::Month)

_val(x) = x
_val(x::DatePeriod) = Dates.value(x)

function _mapreduce(map_fun,reduce_op,gv::GroupedVariable{TV},indices;
                 init = reduce(reduce_op,T[])) where TV <: AbstractArray{T,N} where {T,N}
    data = gv.v
    dim = findfirst(==(Symbol(gv.coordname)),Symbol.(dimnames(data)))
    class = _val.(gv.class)
    unique_class = _val.(gv.unique_class[indices[dim]])
    group_fun = gv.group_fun

    nclass = length(unique_class)
    sz_all = ntuple(i -> (i == dim ? nclass : size(data,i) ),ndims(data))
    sz = size_getindex(sz_all,indices...)

    data_by_class = Array{T,length(sz)}(undef,sz)
    data_by_class .= init

    count = zeros(Int,nclass)
    for k = 1:size(data,dim)
        ku = findfirst(==(class[k]),unique_class)

        if !isnothing(ku)
            dest_ind = _dest_indices(dim,ku,indices)
            src_ind = ntuple(i -> (i == dim ? k : indices[i] ),ndims(data))
            #@show size(data_by_class),dest_ind, indices
            #@show src_ind
            data_by_class_ind = view(data_by_class,dest_ind...)

            data_by_class_ind .= reduce_op.(
                data_by_class_ind,
                map_fun(data[src_ind...]))
            count[ku] += 1
        end
    end

    return data_by_class,reshape(count,_indices(dim,length(count),1,indices))
end

function _reduce(args...; kwargs...)
    _mapreduce(identity,args...; kwargs...)
end

Base.ndims(gr::GroupedVariableResult) = ndims(gr.gv.v)
Base.size(gr::GroupedVariableResult) = ntuple(ndims(gr)) do i
    if i == gr.gv.dim
        length(gr.gv.unique_class)
    else
        size(gr.gv.v,i)
    end
end
dimnames(gr::GroupedVariableResult) = dimnames(gr.gv.v)
name(gr::GroupedVariableResult) = name(gr.gv.v)

struct GroupedVariableStyle <: BroadcastStyle end
struct GroupedVariableResultStyle <: BroadcastStyle end


Base.BroadcastStyle(::Type{<:GroupedVariable}) = GroupedVariableStyle()
Base.BroadcastStyle(::Type{<:GroupedVariableResult}) = GroupedVariableResultStyle()


"""
    A = find_gv(T,As)

returns the first type T among the arguments.
"""
find_gv(T,bc::Base.Broadcast.Broadcasted) = find_gv(T,bc.args)
find_gv(T,args::Tuple) = find_gv(T,find_gv(T,args[1]), Base.tail(args))
find_gv(T,x) = x
find_gv(T,::Tuple{}) = nothing
find_gv(::Type{T},a::T, rest) where T = a
find_gv(T,::Any, rest) = find_gv(T,rest)

function Base.similar(bc::Broadcasted{GroupedVariableStyle}, ::Type{ElType})  where ElType
    A = find_gv(GroupedVariable,bc)
    return A
end


function Base.similar(bc::Broadcasted{GroupedVariableResultStyle}, ::Type{ElType})  where ElType
    # Scan the inputs for the GroupedVariableResult:
    A = find_gv(GroupedVariableResult,bc)
    return similar(A.gv.v)
end


function Base.broadcasted(f,A::GroupedVariable{TV,TF,TClass,TM,TG}) where {TV,TF,TClass,TM,TG}
    # TODO change output TG

    map_fun = ∘(f,A.map_fun)
    TM2 = typeof(map_fun)
    TG2 = TG

    ff = map_fun ∘ Array ∘ selectdim
    #TG = Base.return_types(selectdim,(TV,Int,Int,))[1]
    TG2 = Base.return_types(ff,(TV,Int,Int,))[1]

    GroupedVariable{TV,TF,TClass,TM2,TG2}(
        A.v,A.coordname,A.group_fun,A.class,A.unique_class,A.dim,map_fun)
end

# _array_selectdim_indices(ind,dim,i,sz...)
# returns a tuple (:,:,:,i,:,:,:) where the i is at the dim position
# in total there are as many indices as elements in the tuple sz
# (typically the size of the array)

_array_selectdim_indices(ind,dim,i,sz1,rest...) = _array_selectdim_indices((ind...,(length(ind) == dim-1 ? i : (:))),dim,i,rest...)
_array_selectdim_indices(ind,dim,i) = ind


# indices_B is not type-stable as dim is not know at compile type
# but if i is a range (e.g. 1:2), then the type-unstability does not propagate
function _array_selectdim(B,dim,i)
    indices_B = _array_selectdim_indices((),dim,i,size(B)...)
    return B[indices_B...]
end


_broadcasted_array_selectdim(A::GroupedVariableResult,dim,indices,k) = _array_selectdim(A,dim,k:k)
_broadcasted_array_selectdim(A,dim,indices,k) = _array_selectdim(A,dim,indices)

function broadcasted_gvr!(C,f,A,B)
    gr = find_gv(GroupedVariableResult,(A,B))
    gv = gr.gv
    dim = gr.gv.dim

    unique_class = gv.unique_class
    class = gv.class

    for k = 1:length(unique_class)
        class_k, indices = group(gv,k)

        selectdim(C,dim,indices) .= broadcast(
            f,
            _broadcasted_array_selectdim(A,dim,indices,k),
            _broadcasted_array_selectdim(B,dim,indices,k))
    end

    return C
end


Base.broadcasted(f,A,B::GroupedVariableResult) = broadcasted_gvr!(similar(A),f,A,B)
Base.broadcasted(f,A::GroupedVariableResult,B) = broadcasted_gvr!(similar(B),f,A,B)

_array_selectdim(x) = Array(selectdim(x,1,[1]))


function GroupedVariable(v::TV,coordname,group_fun::TF,class,unique_class,dim,map_fun::TM) where TV <: AbstractVariable where {TF,TM}
    TClass = eltype(class)

    #TG = Base.return_types(selectdim,(TV,Int,Int,))[1]
    TG = Base.return_types(_array_selectdim,(TV,))[1]

    @debug "inferred types" TV TF TClass TM TG
    GroupedVariable{TV,TF,TClass,TM,TG}(
        v,Symbol(coordname),group_fun,class,unique_class,dim,map_fun)
end


"""
    gv = CommonDataModel.groupby(v::AbstractVariable,:coordname => group_fun)
    gv = CommonDataModel.groupby(v::AbstractVariable,"coordname" => group_fun)
    gv = CommonDataModel.@groupby(v,group_fun(coordname))


Create a grouped variable `gv` whose elements composed by all elements in `v`
whose corresponding coordinate variable (with the name `coordname`) map to the
same value once the group function `group_fun` is applied to the coordinate.

The grouped variable `gv` and be reduced using the functions `sum` `mean`,
`median`, `var` or `std`, for example `gr = mean(gv)`.
The result `gr` is a lazy structure representing the
outcome of these operations performed over the grouped dimension. Only when the
result `gr` is indexed the actually values are computed.

Broadcasting for `gv` and `gr` is overloaded. Broadcasting over all elements of
`gv` means that a mapping function is to be applied to all elements of `gv`
before a possible the reduction.
Broadcasting over `gr`, for example `v .- gr` mean that `gr` is broadcasted over the
full size of `v` according to the grouping function.

Example:

```julia
using NCDatasets, Dates
using CommonDataModel: @groupby

# create same test data

time = DateTime(2000,1,1):Day(1):DateTime(2009,12,31);  # 10 years
data = rand(Float32.(-9:99),360,180,length(time));
fname = "test_file.nc"
ds = NCDataset(fname,"c");
defVar(ds,"time",time,("time",));
defVar(ds,"data",data,("lon","lat","time"));

# group over month

gv = @groupby(ds["data"],Dates.Month(time));
length(gv)
# output 12 as they are all 12 months in this dataset
gv[1]
# 360 x 180 x 310 array with all time slices corresponding to the 1st month

# compute basic statistics

using Statistics
monthly_mean = mean(gv)[:,:,:];
size(monthly_mean)
# 360 x 180 x 12 array with the monthly mean

# substact from data the corresponding monthly mean
monthly_anomalies = data .- mean(gv);

close(ds)
```


"""
function groupby(v::TV,(coordname,group_fun)::Pair{<:SymbolOrString,TF}) where TV <: AbstractVariable where TF
    # for NCDatasets 0.12
    c = v[String(coordname)][:]
    class = group_fun.(c)
    unique_class = sort(unique(class))
    dim = findfirst(==(Symbol(coordname)),Symbol.(dimnames(v)))
    map_fun = identity
    return GroupedVariable(v,coordname,group_fun,class,unique_class,dim,map_fun)
end


group(gv::GroupedVariable,k) = gv.unique_class[k]

#GroupedVariableResult(gv,reduce_fun) = GroupedVariableResult(gv,reduce_fun,identity)

function GroupedVariableResult(gv,reduce_fun)
    T = eltype(gv.v)
    N = ndims(gv.v)
    GroupedVariableResult{T,N,typeof(gv),typeof(reduce_fun)}(gv,reduce_fun)
end


Base.sum(gv::GroupedVariable) = GroupedVariableResult(gv,sum)
Statistics.mean(gv::GroupedVariable) = GroupedVariableResult(gv,mean)
Statistics.median(gv::GroupedVariable) = GroupedVariableResult(gv,median)
Statistics.std(gv::GroupedVariable) = GroupedVariableResult(gv,std)
Statistics.var(gv::GroupedVariable) = GroupedVariableResult(gv,var)


function Base.Array(gr::GroupedVariableResult)
    gr[ntuple(i -> Colon(),ndims(gr))...]
end

function Base.getindex(gr::GroupedVariableResult{T,N,TGV,typeof(sum)},indices::Union{Integer,Colon,AbstractRange{<:Integer},AbstractVector{<:Integer}}...) where {T,N,TGV}
    data,count = _mapreduce(gr.gv.map_fun,+,gr.gv,indices)
    data
end

function Base.getindex(gr::GroupedVariableResult{T,N,TGV,typeof(mean)},indices::Union{Integer,Colon,AbstractRange{<:Integer},AbstractVector{<:Integer}}...) where {T,N,TGV}
    data,count = _mapreduce(gr.gv.map_fun,+,gr.gv,indices)
    data ./ count
end

_dim_after_getindex(dim,ind::Union{Colon,AbstractRange,AbstractVector},other...) = _dim_after_getindex(dim+1,other...)
_dim_after_getindex(dim,ind::Integer,other...) = _dim_after_getindex(dim,other...)
_dim_after_getindex(dim) = dim

function Base.getindex(gr::GroupedVariableResult{T},indices::Union{Integer,Colon,AbstractRange{<:Integer},AbstractVector{<:Integer}}...) where T
    gv = gr.gv
    sz = size_getindex(gr,indices...)
    data_by_class = Array{T}(undef,sz)

    # after indexing some dimensions are not longer present
    cdim = _dim_after_getindex(0,indices[1:(gv.dim-1)]...) + 1

    indices_source = ntuple(ndims(gr)) do i
        if i == gv.dim
            (:)
        else
            indices[i]
        end
    end

    for (kl,ku) in enumerate(to_indices(gr,indices)[gv.dim])
        dest_ind = _dest_indices(gv.dim,kl,indices)
        data = gv[ku]
        data_by_class[dest_ind...] = gr.reduce_fun(gv.map_fun(data[indices_source...]),dims=cdim)
    end

    return data_by_class
end

macro groupby(vsym,expression)
    (param, newsym),exp = scan_coordinate_name(expression)
    fun = :($newsym -> $exp)
    return :(groupby($(esc(vsym)),$(Meta.quot(param)) => $fun))
end


function dataset(gr::GroupedVariableResult)
    gv = gr.gv
    ds = dataset(gv.v)

    return GroupedDataset(
        ds,gv.coordname,gv.group_fun,
        gv.class,gv.unique_class,
        gv.map_fun,
        gr.reduce_fun,
    )
end

Base.keys(gds::GroupedDataset) = keys(gds.ds)

function variable(gds::GroupedDataset,varname::SymbolOrString)
    v = variable(gds.ds,varname)

    dim = findfirst(==(gds.coordname),Symbol.(dimnames(v)))
    if isnothing(dim)
        return v
    else
        gv = GroupedVariable(
            v,
            gds.coordname,
            gds.group_fun,
            gds.class,
            gds.unique_class,
            dim,
            gds.map_fun)
        return GroupedVariableResult(gv,gds.reduce_fun)
    end
end
