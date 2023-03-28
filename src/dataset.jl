
"""
    CommonDatamodel.path(ds::AbstractDataset)

File path of the data set `ds`.
"""
path(ds::AbstractDataset) = ""


"""
    CommonDatamodel.groupname(ds::AbstractDataset)

Name of the group of the data set `ds`. For a data set containing
only a single group, this will be always the root group `"/"`.
"""
groupname(ds::AbstractDataset) = "/"


"""
    CommonDatamodel.unlimited(ds::AbstractDataset)

Iterator of strings with the name of the unlimited dimension.
"""
unlimited(ad::AbstractDataset) = ()

Base.isopen(ds::AbstractDataset) = true

"""
    CommonDatamodel.group(ds::AbstractDataset,groupname::AbstractString)

Return the sub-group data set with the name `groupname`.
"""
function group(ds::AbstractDataset,groupname::AbstractString)
    error("no group $groupname in $(path(ds))")
end


function Base.show(io::IO,ds::AbstractDataset)
    level = get(io, :level, 0)
    indent = " " ^ level

    if !isopen(ds)
        print(io,"closed Dataset")
        return
    end

    dspath = path(ds)
    printstyled(io, indent, "Dataset: ",dspath,"\n", color=section_color[])

    print(io,indent,"Group: ",groupname(ds),"\n")
    print(io,"\n")

    # show dimensions
    if length(ds.dim) > 0
        show_dim(io, ds.dim)
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
    if length(ds.attrib) > 0
        printstyled(io, indent, "Global attributes\n",color=section_color[])
        show_attrib(IOContext(io,:level=>level+2),ds.attrib);
    end

    # groups
    groupnames = keys(ds.group)

    if length(groupnames) > 0
        printstyled(io, indent, "Groups\n",color=section_color[])
        for groupname in groupnames
            show(IOContext(io,:level=>level+2),group(ds,groupname))
        end
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
