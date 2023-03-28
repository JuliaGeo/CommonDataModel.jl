"""
    CommonDatamodel.name(v::AbstractVariable)

Return the name of the variable `v` as a string.
"""
name(v::AbstractVariable) = ""


"""
    CommonDatamodel.dimnames(v::AbstractVariable)

Return an iterable of the dimension names of the variable `v`.
"""
dimnames(av::AbstractVariable) = String[]


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
            print(io,indent,"  Datatype:    ",eltype(v),"\n")
            print(io,indent,"  Dimensions:  ",join(dims,delim),"\n")
        else
            print(io,indent,"\n")
        end

        if length(v.attrib) > 0
            print(io,indent,"  Attributes:\n")
            show_attrib(IOContext(io,:level=>level+3),v.attrib)
        end
    catch err
        print(io,"Variable (dataset closed)")
    end
end
