
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
    CommonDatamodel.group(ds::AbstractDataset,groupname::AbstractString)

Return the sub-group data set with the name `groupname`.
"""
function group(ds::AbstractDataset,groupname::AbstractString)
    error("no group $groupname in $(path(ds))")
end

"""
    group = CommonDatamodel.defGroup(ds::AbstractDataset,name::AbstractString)

Create an empty sub-group with the name `name` in the data set `ds`.
The `group` is a sub-type of `AbstractDataset`.
"""
function defGroup(ds::AbstractDataset,name::AbstractString)
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
