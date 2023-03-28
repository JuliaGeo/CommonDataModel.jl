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
