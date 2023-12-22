module CommonDataModel

using Base.Broadcast: Broadcasted, BroadcastStyle
using CFTime
using Dates
using Printf
using Preferences
using DataStructures
import Base:
    close,
    collect,
    display,
    filter,
    getindex,
    isopen,
    iterate,
    ndims,
    reduce,
    show,
    size,
    write
import Statistics
import Statistics:
    maximum,
    mean,
    median,
    minimum,
    std,
    sum,
    var




include("CatArrays.jl")
include("types.jl")
include("dataset.jl")
include("variable.jl")
include("cfvariable.jl")
include("attribute.jl")
include("dimension.jl")
include("cfconventions.jl")
include("multifile.jl")
include("defer.jl")
include("subvariable.jl")
include("select.jl")
include("aggregation.jl")
include("groupby.jl")

end # module CommonDataModel

#  LocalWords:  AbstractDataset NetCDF GRIB ds AbstractVariable
#  LocalWords:  varname dimnames iterable attribnames attrib dataset
#  LocalWords:  groupnames AbstractArray
