"""
    CommonDatamodel.show_attrib(io,a)

Print a list all attributes (key/values pairs) in `a` to IO stream `io`.
The IO property `:level` is used for indentation.
"""
function show_attrib(io,a)
    level = get(io, :level, 0)
    indent = " " ^ level

    # if !isopen(ds)
    #     print(io,"closed Dataset")
    #     return
    # end

    try
        # use the same order of attributes than in the NetCDF file
        for (attname,attval) in a
            print(io,indent,@sprintf("%-20s = ",attname))
            printstyled(io, @sprintf("%s",attval),color=attribute_color[])
            print(io,"\n")
        end
    catch err
        print(io,"Dataset attributes (file closed)")
        # if isa(err,NetCDFError)
        #     if err.code == NC_EBADID
        #         print(io,"Dataset  attributes (file closed)")
        #         return
        #     end
        # end
        # rethrow()
    end
end
