
"""
    CommonDatamodel.path(ds::AbstractDataset)

File path of the data set `ds`.
"""
path(ds::AbstractDataset) = ""


Base.close(ds::AbstractDataset) = nothing

"""
    CommonDatamodel.name(ds::AbstractDataset)

Name of the group of the data set `ds`. For a data set containing
only a single group, this will be always the root group `"/"`.
"""
name(ds::AbstractDataset) = "/"

"""
    CommonDatamodel.groupnames(ds::AbstractDataset)

All the subgroup names of the data set `ds`. For a data set containing
only a single group, this will be an empty vector of `String`.
"""
groupnames(ds::AbstractDataset) = ()


"""
    CommonDatamodel.group(ds::AbstractDataset,groupname::SymbolOrString)

Return the sub-group data set with the name `groupname`.
"""
function group(ds::AbstractDataset,groupname::SymbolOrString)
    error("no group $groupname in $(path(ds))")
end

"""
    group = CommonDatamodel.defGroup(ds::AbstractDataset,name::SymbolOrString)

Create an empty sub-group with the name `name` in the data set `ds`.
The `group` is a sub-type of `AbstractDataset`.
"""
function defGroup(ds::AbstractDataset,name::SymbolOrString)
    error("unimplemented for abstract type")
end

"""
    CommonDatamodel.groups(ds::AbstractDataset)

Return all sub-group data as a dict-like object.
"""
groups(ds::AbstractDataset) =
    OrderedDict((dn,group(ds,dn)) for dn in groupnames(ds))


"""
    CommonDatamodel.unlimited(ds::AbstractDataset)

Iterator of strings with the name of the unlimited dimension.
"""
unlimited(ad::AbstractDataset) = ()

Base.isopen(ds::AbstractDataset) = true



function Base.show(io::IO,ds::AbstractDataset)
    level = get(io, :level, 0)
    indent = " " ^ level

    if !isopen(ds)
        print(io,"closed Dataset")
        return
    end

    dspath = path(ds)
    printstyled(io, indent, "Dataset: ",dspath,"\n", color=section_color[])

    print(io,indent,"Group: ",name(ds),"\n")
    print(io,"\n")

    # show dimensions
    if length(dimnames(ds)) > 0
        show_dim(io, dims(ds))
        print(io,"\n")
    end

    varnames = keys(ds)

    if length(varnames) > 0
        printstyled(io, indent, "Variables\n",color=section_color[])

        for name in varnames
            show(IOContext(io,:level=>level+2),ds[name])
            print(io,"\n")
        end
    end

    # global attribues
    if length(attribnames(ds)) > 0
        printstyled(io, indent, "Global attributes\n",color=section_color[])
        show_attrib(IOContext(io,:level=>level+2),attribs(ds));
    end

    # groups
    gnames = groupnames(ds)

    if length(gnames) > 0
        printstyled(io, indent, "Groups\n",color=section_color[])
        for groupname in gnames
            show(IOContext(io,:level=>level+2),group(ds,groupname))
        end
    end

end


Base.getindex(ds::AbstractDataset,varname) = cfvariable(ds,varname)



"""
    varbyattrib(ds, attname = attval)

Returns a list of variable(s) which has the attribute `attname` matching the value `attval`
in the dataset `ds`.
The list is empty if the none of the variables has the match.
The output is a list of `CFVariable`s.

# Examples

Load all the data of the first variable with standard name "longitude" from the
NetCDF file `results.nc`.

```julia-repl
julia> ds = NCDataset("results.nc", "r");
julia> data = varbyattrib(ds, standard_name = "longitude")[1][:]
```

"""
function varbyattrib(ds::Union{AbstractDataset,AbstractVariable}; kwargs...)
    # Start with an empty list of variables
    varlist = []

    # Loop on the variables
    for v in keys(ds)
        var = ds[v]

        matchall = true

        for (attsym,attval) in kwargs
            attname = String(attsym)

            # Check if the variable has the desired attribute
            if attname in attribnames(var)
                # Check if the attribute value is the selected one
                if attrib(var,attname) != attval
                    matchall = false
                    break
                end
            else
                matchall = false
                break
            end
        end

        if matchall
            push!(varlist, var)
        end
    end

    return varlist
end

# avoid ambiguity
function getindex_byname(ds::Union{AbstractDataset,AbstractVariable},n::CFStdName)
    ncvars = varbyattrib(ds, standard_name = String(n.name))
    if length(ncvars) == 1
        return ncvars[1]
    else
        throw(KeyError("$(length(ncvars)) matches while searching for a variable with standard_name attribute equal to $(n.name)"))
    end
end

Base.getindex(ds::AbstractDataset,n::CFStdName) = getindex_byname(ds,n)
Base.getindex(v::AbstractVariable,n::CFStdName) = getindex_byname(v,n)


Base.keys(groups::Groups) = groupnames(groups.ds)
Base.getindex(groups::Groups,name) = group(groups.ds,name)


"Initialize the ds._boundsmap variable"
function initboundsmap!(ds)
    empty!(ds._boundsmap)
    for vname in keys(ds)
        v = variable(ds,vname)
        bounds = get(v.attrib,"bounds",nothing)

        if bounds !== nothing
            ds._boundsmap[bounds] = vname
        end
    end
end

@inline function Base.getproperty(ds::Union{AbstractDataset,AbstractVariable},name::Symbol)
    if (name == :attrib) && !hasfield(typeof(ds),name)
        return Attributes(ds)
    elseif (name == :dim) && !hasfield(typeof(ds),name)
        return Dimensions(ds)
    elseif (name == :group) && !hasfield(typeof(ds),name) && (ds isa AbstractDataset)
        return Groups(ds)
    else
        return getfield(ds,name)
    end
end


for (item_color,default) in (
    (:section_color, :red),
    (:attribute_color, :cyan),
    (:variable_color, :green),
)

    item_color_str = String(item_color)
    item_str = split(item_color_str,"_")[1]
    default_str = String(default)

    @eval begin
        $item_color = Ref(Symbol(load_preference(CommonDataModel,$(item_color_str), $(QuoteNode(default)))))

        """
        CommonDataModel.set_$($item_color_str)(color::Symbol)

Set the $($item_str) color. The default color is `$($default_str)`.
"""
        function $(Symbol(:set_,item_color))(color::Symbol)
            @set_preferences!($(item_color_str) => String(color))
            $item_color[] = color
        end

    end
end
