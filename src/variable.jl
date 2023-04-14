"""
    CommonDataModel.name(v::AbstractVariable)

Return the name of the variable `v` as a string.
"""
name(v::AbstractVariable) = ""


"""
    CommonDataModel.dimnames(v::AbstractVariable)

Return an iterable of the dimension names of the variable `v`.
"""
dimnames(av::AbstractVariable) = ()


"""
    CommonDataModel.varnames(ds::AbstractDataset)

Return an iterable of all the variable name.
"""
varnames(ds::AbstractDataset) = ()

"""
    CommonDataModel.variable(ds::AbstractDataset,variablename::SymbolOrString)

Return the variable with the name `variablename` from the data set `ds`.
"""
function variable(ds::AbstractDataset,variablename::SymbolOrString)
    error("no variable $variablename in $(path(ds)) (abstract method)")
end

function defVar(ds::AbstractDataset,name::SymbolOrString,type,dimnames)
    error("unimplemented for abstract type")
end

"""
    ds = CommonDataModel.dataset(v::AbstractVariable)

Return the data set `ds` to which a the variable `v` belongs to.
"""
function dataset(v::AbstractVariable)
    error("unimplemented for abstract type")
end

function Base.parent(var::AbstractVariable)
    error("unimplemented for abstract type")
end

function readblock!(A::AbstractVariable, aout, i::AbstractUnitRange...)
    readblock!(parent(A), aout, i...)
end

function writeblock!(A::AbstractVariable, v, i::AbstractUnitRange...)
    writeblock!(parent(A), v, i...)
end

eachchunk(A::AbstractVariable) = GridChunks(A, size(A))
haschunks(A::AbstractVariable) = Unchunked()

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

            print(io,indent,"  Datatype:    ")
            printstyled(io,eltype(v),bold=true)
            if v isa CFVariable
                print(io," (",eltype(v.var),")")
            end
            print(io,"\n")
            print(io,indent,"  Dimensions:  ",join(dims,delim),"\n")
        else
            print(io,indent,"\n")
        end

        if length(v.attrib) > 0
            print(io,indent,"  Attributes:\n")
            show_attrib(IOContext(io,:level=>level+3),attribs(v))
        end
    catch err
        @debug "error in show" err
        print(io,"Variable (dataset closed)")
    end
end
