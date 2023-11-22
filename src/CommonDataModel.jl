module CommonDataModel

using CFTime
using Dates
using Printf
using Preferences
import Base: isopen, show, display, close, filter, collect, write
using DataStructures


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

end # module CommonDataModel

#  LocalWords:  AbstractDataset NetCDF GRIB ds AbstractVariable
#  LocalWords:  varname dimnames iterable attribnames attrib dataset
#  LocalWords:  groupnames AbstractArray
