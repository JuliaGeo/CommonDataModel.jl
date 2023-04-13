
"""
    CommonDatamodel.dimnames(ds::AbstractDataset)

Return an iterable of all dimension names in `ds`.
"""
dimnames(ds::Union{AbstractDataset,AbstractVariable}) = ()


"""
    CommonDatamodel.dim(ds::AbstractDataset,dimname::AbstractString)

Return the length of the dimension `dimname` in the data set `ds`.
"""
dim(v::AbstractVariable,name::AbstractString) = dim(dataset(v),name)

function dim(ds::AbstractDataset,dimname::AbstractString)
    error("no dimension $dimname in $(path(ds))")
end

"""
    CommonDatamodel.defDim(ds::AbstractDataset,name::AbstractString,len)

Create dimension with the name `name` in the data set `ds` with the length `len`.
`len` can be `Inf` for unlimited dimensions.
"""
function defDim(ds::AbstractDataset,name::AbstractString,len)
    error("unimplemnted for abstract type")
end


"""
    CommonDatamodel.dims(ds::Union{AbstractDataset,AbstractVariable})

Return a dict-like of all dimensions and their corresponding length defined in the the data set `ds` (or variable).
"""
dims(ds::Union{AbstractDataset,AbstractVariable}) =
    OrderedDict((dn,dim(ds,dn)) for dn in dimnames(ds))



"""
    CommonDatamodel.show_dim(io,dim)

Print a list all dimensions (key/values pairs where key is the dimension names
and value the corresponding length) in `dim` to IO stream `io`.
The IO property `:level` is used for indentation.
"""
function show_dim(io::IO, d)
    level = get(io, :level, 0)
    indent = " " ^ level

    printstyled(io, indent, "Dimensions\n",color=section_color[])
    try
        for (dimname,dimlen) in d
            print(io,indent,"   $(dimname) = $(dimlen)\n")
        end
    catch err
        print(io, "Dimensions (file closed)")
    end
end
