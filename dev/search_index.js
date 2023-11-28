var documenterSearchIndex = {"docs":
[{"location":"#Data-types","page":"Home","title":"Data types","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"In order to implement a new dataset based CommonDataModel.jl one has to create two types derived from:","category":"page"},{"location":"","page":"Home","title":"Home","text":"AbstractVariable: a variable with named dimension and metadata\nAbstractDataset: a collection of variable with named dimension, metadata and sub-groups. The sub-groups are also AbstractDataset.","category":"page"},{"location":"","page":"Home","title":"Home","text":"CommonDataModel.jl also provides a type CFVariable which wraps a type derived from AbstractVariable and applies the scaling described in cfvariable.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Overview of methods:","category":"page"},{"location":"","page":"Home","title":"Home","text":" get names get values set value property\nDimensions dimnames dim defDim dim\nAttributes attribnames attrib defAttrib attrib\nVariables varnames variable defVar -\nGroups groupnames group defGroup group","category":"page"},{"location":"","page":"Home","title":"Home","text":"For read-only datasets, the methods in \"set value\" column are not to be implemented. Attributes can also be delete with the delAttrib functions.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Every struct deriving from AbstractDataset have automaticaly the special properties dim, attrib and group which act like dictionaries (unless a field with this name already exists). For attrib, calls to keys, getindex and setindex!, delete! are dispated to attribnames, attrib,defAttrib, and delAttrib respectively (and likewise for other properties). For example:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using NCDatasets\nds = NCDataset(\"file.nc\")\n# setindex!(ds.attrib,...) here automatically calls defAttrib(ds,...)\nds.attrib[\"title\"] = \"my amazing results\";","category":"page"},{"location":"","page":"Home","title":"Home","text":"Every struct deriving from AbstractVariable have the properties dim, and attrib.","category":"page"},{"location":"#API","page":"Home","title":"API","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [CommonDataModel, CommonDataModel.CatArrays]","category":"page"},{"location":"#CommonDataModel.AbstractDataset","page":"Home","title":"CommonDataModel.AbstractDataset","text":"AbstractDataset is a collection of multidimensional variables (for example a NetCDF or GRIB file)\n\nA data set ds of a type derived from AbstractDataset should implemented at minimum:\n\nBase.key(ds): return a list of variable names as strings\nvariable(ds,varname::String): return an array-like data structure (derived from AbstractVariable) of the variables corresponding to varname. This array-like data structure should follow the CF semantics.\ndimnames(ds): should be an iterable with all dimension names in the data set  ds\ndim(ds,name): dimension value corresponding to name\n\nOptionally a data set can have attributes and groups:\n\nattribnames(ds): should be an iterable with all attribute names\nattrib(ds,name): attribute value corresponding to name\ngroupnames(ds): should be an iterable with all group names\ngroup(ds,name): group corresponding to the name\n\nFor a writable dataset, one should also implement:\n\ndefDim: define a dimension\ndefAttrib: define a attribute\ndefVar: define a variable\ndefGroup: define a group\n\n\n\n\n\n","category":"type"},{"location":"#CommonDataModel.AbstractVariable","page":"Home","title":"CommonDataModel.AbstractVariable","text":"AbstractVariable{T,N} is a subclass of AbstractArray{T, N}. A variable v of a type derived from AbstractVariable should implement:\n\nname(v): should be the name of variable within the data set\ndimnames(v): should be a iterable data structure with all dimension names of the variable v\ndataset(v): the parent dataset containing v\nBase.size(v): the size of the variable\nBase.getindex(v,indices...): get the data of v at the provided indices\n\nOptionally a variable can have attributes:\n\nattribnames(v): should be an iterable with all attribute names\nattrib(v,name): attribute value corresponding to name\n\nFor a writable dataset, one should also implement:\n\ndefAttrib: define a attribute\nBase.setindex!(v,data,indices...): set the data in v at the provided indices\n\n\n\n\n\n","category":"type"},{"location":"#CommonDataModel.Attributes","page":"Home","title":"CommonDataModel.Attributes","text":"A collection of attributes with a Dict-like interface dispatching to attribnames, attrib, defAttrib for keys, getindex and setindex! respectively.\n\n\n\n\n\n","category":"type"},{"location":"#CommonDataModel.CFVariable","page":"Home","title":"CommonDataModel.CFVariable","text":"Variable (with applied transformations following the CF convention)\n\n\n\n\n\n","category":"type"},{"location":"#CommonDataModel.Dimensions","page":"Home","title":"CommonDataModel.Dimensions","text":"A collection of dimensions with a Dict-like interface dispatching to dimnames, dim, defDim for keys, getindex and setindex! respectively.\n\n\n\n\n\n","category":"type"},{"location":"#CommonDataModel.Groups","page":"Home","title":"CommonDataModel.Groups","text":"A collection of groups with a Dict-like interface dispatching to groupnames and group for keys and getindex respectively.\n\n\n\n\n\n","category":"type"},{"location":"#Base.collect-Union{Tuple{CommonDataModel.SubVariable{T, N}}, Tuple{T}, Tuple{N}} where {N, T}","page":"Home","title":"Base.collect","text":"collect always returns an array. Even if the result of the indexing is a scalar, it is wrapped into a zero-dimensional array.\n\n\n\n\n\n","category":"method"},{"location":"#Base.delete!-Tuple{CommonDataModel.Attributes, Union{AbstractString, Symbol}}","page":"Home","title":"Base.delete!","text":"Base.delete!(a::Attributes, name)\n\nDelete the attribute name from the attribute list a.\n\n\n\n\n\n","category":"method"},{"location":"#Base.filter-Tuple{CommonDataModel.AbstractVariable, Vararg{Any}}","page":"Home","title":"Base.filter","text":"data = CommonDataModel.filter(ncv, indices...; accepted_status_flags = nothing)\n\nLoad and filter observations by replacing all variables without an acepted status flag to missing. It is used the attribute ancillary_variables to identify the status flag.\n\n# da[\"data\"] is 2D matrix\ngood_data = NCDatasets.filter(ds[\"data\"],:,:, accepted_status_flags = [\"good_data\",\"probably_good_data\"])\n\n\n\n\n\n","category":"method"},{"location":"#Base.getindex-Tuple{CommonDataModel.AbstractDataset, Union{AbstractString, Symbol}}","page":"Home","title":"Base.getindex","text":"v = getindex(ds::NCDataset, varname::AbstractString)\n\nReturn the variable varname in the dataset ds as a CFVariable. The following CF convention are honored when the variable is indexed:\n\n_FillValue or missing_value (which can be a list) will be returned as missing.\nscale_factor and add_offset are applied (output = scale_factor * data_in_file +  add_offset)\ntime variables (recognized by the units attribute and possibly the calendar attribute) are returned usually as DateTime object. Note that CFTime.DateTimeAllLeap, CFTime.DateTimeNoLeap and CF.TimeDateTime360Day cannot be converted to the proleptic gregorian calendar used in julia and are returned as such. (See CFTime.jl for more information about those date types.) If a calendar is defined but not among the ones specified in the CF convention, then the data in the file is not converted into a date structure.\n\nA call getindex(ds, varname) is usually written as ds[varname].\n\nIf variable represents a cell boundary, the attributes calendar and units of the related variables are used, if they are not specified. For example:\n\ndimensions:\n  time = UNLIMITED; // (5 currently)\n  nv = 2;\nvariables:\n  double time(time);\n    time:long_name = \"time\";\n    time:units = \"hours since 1998-04-019 06:00:00\";\n    time:bounds = \"time_bnds\";\n  double time_bnds(time,nv);\n\nIn this case, the variable time_bnds uses the units and calendar of time because both variables are related thought the bounds attribute following the CF conventions.\n\nSee also cfvariable(ds, varname).\n\n\n\n\n\n","category":"method"},{"location":"#Base.getindex-Tuple{CommonDataModel.Attributes, Any}","page":"Home","title":"Base.getindex","text":"getindex(a::Attributes,name::SymbolOrString)\n\nReturn the value of the attribute called name from the attribute list a. Generally the attributes are loaded by indexing, for example:\n\nusing NCDatasets\nds = NCDataset(\"file.nc\")\ntitle = ds.attrib[\"title\"]\n\n\n\n\n\n","category":"method"},{"location":"#Base.keys-Tuple{CommonDataModel.Attributes}","page":"Home","title":"Base.keys","text":"Base.keys(a::Attributes)\n\nReturn a list of the names of all attributes.\n\n\n\n\n\n","category":"method"},{"location":"#Base.setindex!-Tuple{CommonDataModel.Attributes, Any, Any}","page":"Home","title":"Base.setindex!","text":"Base.setindex!(a::Attributes,data,name::SymbolOrString)\n\nSet the attribute called name to the value data in the attribute list a. data can be a vector or a scalar. A scalar is handeld as a vector with one element in the NetCDF data model.\n\nGenerally the attributes are defined by indexing, for example:\n\nds = NCDataset(\"file.nc\",\"c\")\nds.attrib[\"title\"] = \"my title\"\nclose(ds)\n\n\n\n\n\n","category":"method"},{"location":"#Base.size-Tuple{CommonDataModel.CFVariable}","page":"Home","title":"Base.size","text":"sz = size(var::CFVariable)\n\nReturn a tuple of integers with the size of the variable var.\n\nnote: Note\nNote that the size of a variable can change, i.e. for a variable with an unlimited dimension.\n\n\n\n\n\n","category":"method"},{"location":"#Base.view-Tuple{CommonDataModel.AbstractVariable, Vararg{Union{Colon, Int64, AbstractVector{Int64}}}}","page":"Home","title":"Base.view","text":"sv = view(v::CommonDataModel.AbstractVariable,indices...)\n\nReturns a view of the variable v where indices are only lazily applied. No data is actually copied or loaded. Modifications to a view sv, also modifies the underlying array v. All attributes of v are also present in sv.\n\nExamples\n\nusing NCDatasets\nfname = tempname()\ndata = zeros(Int,10,11)\nds = NCDataset(fname,\"c\")\nncdata = defVar(ds,\"temp\",data,(\"lon\",\"lat\"))\nncdata_view = view(ncdata,2:3,2:4)\nsize(ncdata_view)\n# output (2,3)\nncdata_view[1,1] = 1\nncdata[2,2]\n# outputs 1 as ncdata is also modified\nclose(ds)\n\n\n\n\n\n","category":"method"},{"location":"#Base.write-Tuple{CommonDataModel.AbstractDataset, CommonDataModel.AbstractDataset}","page":"Home","title":"Base.write","text":"write(dest::AbstractDataset, src::AbstractDataset; include = keys(src), exclude = [])\n\nWrite the variables of src dataset into an empty dest dataset (which must be opened in mode \"a\" or \"c\"). The keywords include and exclude configure which variable of src should be included (by default all), or which should be excluded (by default none).\n\nIf the first argument is a file name, then the dataset is open in create mode (\"c\").\n\nThis function is useful when you want to save the dataset from a multi-file dataset.\n\nTo save a subset, one can use the view function view to virtually slice a dataset:\n\nExample\n\nNCDataset(fname_src) do ds\n    write(fname_slice,view(ds, lon = 2:3))\nend\n\nAll variables in the source file fname_src with a dimension lon will be sliced along the indices 2:3 for the lon dimension. All attributes (and variables without a dimension lon) will be copied over unmodified.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.ancillaryvariables-Tuple{CommonDataModel.CFVariable, Any}","page":"Home","title":"CommonDataModel.ancillaryvariables","text":"ncvar = CommonDataModel.ancillaryvariables(ncv::CFVariable,modifier)\n\nReturn the first ancillary variables from the NetCDF (or other format) variable ncv with the standard name modifier modifier. It can be used for example to access related variable like status flags.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.attrib-Tuple{Union{CommonDataModel.AbstractDataset, CommonDataModel.AbstractVariable}, Union{AbstractString, Symbol}}","page":"Home","title":"CommonDataModel.attrib","text":"CommonDatamodel.attrib(ds::Union{AbstractDataset,AbstractVariable},attribname::SymbolOrString)\n\nReturn the value of the attribute attribname in the data set ds.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.attribnames-Tuple{Union{CommonDataModel.AbstractDataset, CommonDataModel.AbstractVariable}}","page":"Home","title":"CommonDataModel.attribnames","text":"CommonDatamodel.attribnames(ds::Union{AbstractDataset,AbstractVariable})\n\nReturn an iterable of all attribute names in ds.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.bounds-Tuple{CommonDataModel.CFVariable}","page":"Home","title":"CommonDataModel.bounds","text":"b = bounds(ncvar::NCDatasets.CFVariable)\n\nReturn the CFVariable corresponding to the bounds attribute of the variable ncvar. The time units and calendar from the ncvar are used but not the attributes controling the packing of data scale_factor, add_offset and _FillValue.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.cfvariable-Tuple{Any, Any}","page":"Home","title":"CommonDataModel.cfvariable","text":"v = cfvariable(ds::NCDataset,varname::SymbolOrString; <attrib> = <value>)\n\nReturn the variable varname in the dataset ds as a NCDataset.CFVariable. The keyword argument <attrib> are the attributes (fillvalue, missing_value, scale_factor, add_offset, units and calendar) relevant to the CF conventions. By specifing the value of these attributes, the one can override the value specified in the data set. If the attribute is set to nothing, then the attribute is not loaded and the corresponding transformation is ignored. This function is similar to ds[varname] with the additional flexibility that some variable attributes can be overridden.\n\nExample:\n\nNCDataset(\"foo.nc\",\"c\") do ds\n  defVar(ds,\"data\",[10., 11., 12., 13.], (\"time\",), attrib = Dict(\n      \"add_offset\" => 10.,\n      \"scale_factor\" => 0.2))\nend\n\n# The stored (packed) valued are [0., 5., 10., 15.]\n# since 0.2 .* [0., 5., 10., 15.] .+ 10 is [10., 11., 12., 13.]\n\nds = NCDataset(\"foo.nc\");\n\n@show ds[\"data\"].var[:]\n# returns [0., 5., 10., 15.]\n\n@show cfvariable(ds,\"data\")[:]\n# returns [10., 11., 12., 13.]\n\n# neither add_offset nor scale_factor are applied\n@show cfvariable(ds,\"data\", add_offset = nothing, scale_factor = nothing)[:]\n# returns [0, 5, 10, 15]\n\n# add_offset is applied but not scale_factor\n@show cfvariable(ds,\"data\", scale_factor = nothing)[:]\n# returns [10, 15, 20, 25]\n\n# 0 is declared as the fill value (add_offset and scale_factor are applied as usual)\n@show cfvariable(ds,\"data\", fillvalue = 0)[:]\n# return [missing, 11., 12., 13.]\n\n# Use the time units: days since 2000-01-01\n@show cfvariable(ds,\"data\", units = \"days since 2000-01-01\")[:]\n# returns [DateTime(2000,1,11), DateTime(2000,1,12), DateTime(2000,1,13), DateTime(2000,1,14)]\n\nclose(ds)\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.chunking-Tuple{CommonDataModel.MFVariable}","page":"Home","title":"CommonDataModel.chunking","text":"storage,chunksizes = chunking(v::MFVariable)\n\nReturn the storage type (:contiguous or :chunked) and the chunk sizes of the varable v corresponding to the first file. If the first file in the collection is chunked then this storage attributes are returns. If not the first file is not contiguous, then multi-file variable is still reported as chunked with chunk size equal to the variable size.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.coord-Tuple{CommonDataModel.AbstractVariable, Any}","page":"Home","title":"CommonDataModel.coord","text":"cv = coord(v::Union{CFVariable,Variable},standard_name)\n\nFind the coordinate of the variable v by the standard name standard_name or some standardized heuristics based on units. If the heuristics fail to detect the coordinate, consider to modify the file to add the standard_name attribute. All dimensions of the coordinate must also be dimensions of the variable v.\n\nExample\n\nusing NCDatasets\nds = NCDataset(\"file.nc\")\nncv = ds[\"SST\"]\nlon = coord(ncv,\"longitude\")[:]\nlat = coord(ncv,\"latitude\")[:]\nv = ncv[:]\nclose(ds)\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.dataset-Tuple{CommonDataModel.AbstractVariable}","page":"Home","title":"CommonDataModel.dataset","text":"ds = CommonDataModel.dataset(v::AbstractVariable)\n\nReturn the data set ds to which a the variable v belongs to.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.defAttrib-Tuple{CommonDataModel.AbstractDataset, Union{AbstractString, Symbol}, Any}","page":"Home","title":"CommonDataModel.defAttrib","text":"CommonDatamodel.defAttrib(ds::Union{AbstractDataset,AbstractVariable},name::SymbolOrString,data)\n\nCreate an attribute with the name attrib in the data set or variable ds.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.defDim-Tuple{CommonDataModel.AbstractDataset, Union{AbstractString, Symbol}, Any}","page":"Home","title":"CommonDataModel.defDim","text":"CommonDatamodel.defDim(ds::AbstractDataset,name::SymbolOrString,len)\n\nCreate dimension with the name name in the data set ds with the length len. len can be Inf for unlimited dimensions.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.defGroup-Tuple{CommonDataModel.AbstractDataset, Union{AbstractString, Symbol}}","page":"Home","title":"CommonDataModel.defGroup","text":"group = CommonDatamodel.defGroup(ds::AbstractDataset,name::SymbolOrString)\n\nCreate an empty sub-group with the name name in the data set ds. The group is a sub-type of AbstractDataset.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.defVar-Tuple{CommonDataModel.AbstractDataset, CommonDataModel.AbstractVariable}","page":"Home","title":"CommonDataModel.defVar","text":"v = CommonDataModel.defVar(ds::AbstractDataset,src::AbstractVariable)\n\nDefines and return the variable in the data set ds copied from the variable src. The variable name, dimension name, attributes and data are copied from src.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.delAttrib-Tuple{Union{CommonDataModel.AbstractDataset, CommonDataModel.AbstractVariable}, Union{AbstractString, Symbol}, Any}","page":"Home","title":"CommonDataModel.delAttrib","text":"CommonDatamodel.delAttrib(ds::Union{AbstractDataset,AbstractVariable},name::SymbolOrString,data)\n\nDeletes an attribute with the name attrib in the data set or variable ds.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.dim-Tuple{CommonDataModel.AbstractVariable, Union{AbstractString, Symbol}}","page":"Home","title":"CommonDataModel.dim","text":"CommonDatamodel.dim(ds::AbstractDataset,dimname::SymbolOrString)\n\nReturn the length of the dimension dimname in the data set ds.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.dimnames-Tuple{CommonDataModel.AbstractVariable}","page":"Home","title":"CommonDataModel.dimnames","text":"CommonDataModel.dimnames(v::AbstractVariable)\n\nReturn an iterable of the dimension names of the variable v.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.dimnames-Tuple{Union{CommonDataModel.AbstractDataset, CommonDataModel.AbstractVariable}}","page":"Home","title":"CommonDataModel.dimnames","text":"CommonDatamodel.dimnames(ds::AbstractDataset)\n\nReturn an iterable of all dimension names in ds. This information can also be accessed using the property ds.dim:\n\nExamples\n\nds = NCDataset(\"results.nc\", \"r\");\ndimnames = keys(ds.dim)\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.dimnames-Tuple{Union{CommonDataModel.CFVariable, CommonDataModel.MFCFVariable}}","page":"Home","title":"CommonDataModel.dimnames","text":"dimnames(v::CFVariable)\n\nReturn a tuple of strings with the dimension names of the variable v.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.dims-Tuple{Union{CommonDataModel.AbstractDataset, CommonDataModel.AbstractVariable}}","page":"Home","title":"CommonDataModel.dims","text":"CommonDatamodel.dims(ds::Union{AbstractDataset,AbstractVariable})\n\nReturn a dict-like of all dimensions and their corresponding length defined in the the data set ds (or variable).\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.group-Tuple{CommonDataModel.AbstractDataset, Union{AbstractString, Symbol}}","page":"Home","title":"CommonDataModel.group","text":"CommonDatamodel.group(ds::AbstractDataset,groupname::SymbolOrString)\n\nReturn the sub-group data set with the name groupname.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.groupnames-Tuple{CommonDataModel.AbstractDataset}","page":"Home","title":"CommonDataModel.groupnames","text":"CommonDatamodel.groupnames(ds::AbstractDataset)\n\nAll the subgroup names of the data set ds. For a data set containing only a single group, this will be an empty vector of String.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.groups-Tuple{CommonDataModel.AbstractDataset}","page":"Home","title":"CommonDataModel.groups","text":"CommonDatamodel.groups(ds::AbstractDataset)\n\nReturn all sub-group data as a dict-like object.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.load!-Union{Tuple{N}, Tuple{T}, Tuple{Union{CommonDataModel.CFVariable{T, N}, CommonDataModel.MFCFVariable{T, N}, CommonDataModel.SubVariable{T, N}}, Any, Any, Vararg{Union{Colon, Integer, AbstractRange{<:Integer}}}}} where {T, N}","page":"Home","title":"CommonDataModel.load!","text":"CommonDataModel.load!(ncvar::CFVariable, data, buffer, indices)\n\nLoads a NetCDF (or other format) variables ncvar in-place and puts the result in data (an array of eltype(ncvar)) along the specified indices. buffer is a temporary  array of the same size as data but the type should be eltype(ncv.var), i.e. the corresponding type in the files (before applying scale_factor, add_offset and masking fill values). Scaling and masking will be applied to the array data.\n\ndata and buffer can be the same array if eltype(ncvar) == eltype(ncvar.var).\n\nExample:\n\n# create some test array\nDataset(\"file.nc\",\"c\") do ds\n    defDim(ds,\"time\",3)\n    ncvar = defVar(ds,\"vgos\",Int16,(\"time\",),attrib = [\"scale_factor\" => 0.1])\n    ncvar[:] = [1.1, 1.2, 1.3]\n    # store 11, 12 and 13 as scale_factor is 0.1\nend\n\n\nds = Dataset(\"file.nc\")\nncv = ds[\"vgos\"];\n# data and buffer must have the right shape and type\ndata = zeros(eltype(ncv),size(ncv)); # here Vector{Float64}\nbuffer = zeros(eltype(ncv.var),size(ncv)); # here Vector{Int16}\nNCDatasets.load!(ncv,data,buffer,:,:,:)\nclose(ds)\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.name-Tuple{CommonDataModel.AbstractDataset}","page":"Home","title":"CommonDataModel.name","text":"CommonDatamodel.name(ds::AbstractDataset)\n\nName of the group of the data set ds. For a data set containing only a single group, this will be always the root group \"/\".\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.name-Tuple{CommonDataModel.AbstractVariable}","page":"Home","title":"CommonDataModel.name","text":"CommonDataModel.name(v::AbstractVariable)\n\nReturn the name of the variable v as a string.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.path-Tuple{CommonDataModel.AbstractDataset}","page":"Home","title":"CommonDataModel.path","text":"CommonDatamodel.path(ds::AbstractDataset)\n\nFile path of the data set ds.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.set_attribute_color-Tuple{Symbol}","page":"Home","title":"CommonDataModel.set_attribute_color","text":"    CommonDataModel.set_attribute_color(color::Symbol)\n\nSet the attribute color. The default color is cyan.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.set_section_color-Tuple{Symbol}","page":"Home","title":"CommonDataModel.set_section_color","text":"    CommonDataModel.set_section_color(color::Symbol)\n\nSet the section color. The default color is red.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.set_variable_color-Tuple{Symbol}","page":"Home","title":"CommonDataModel.set_variable_color","text":"    CommonDataModel.set_variable_color(color::Symbol)\n\nSet the variable color. The default color is green.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.show_dim-Tuple{IO, Any}","page":"Home","title":"CommonDataModel.show_dim","text":"CommonDatamodel.show_dim(io,dim)\n\nPrint a list all dimensions (key/values pairs where key is the dimension names and value the corresponding length) in dim to IO stream io. The IO property :level is used for indentation.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.time_factor-Tuple{CommonDataModel.CFVariable}","page":"Home","title":"CommonDataModel.time_factor","text":"tf = CommonDataModel.time_factor(v::CFVariable)\n\nThe time unit in milliseconds. E.g. seconds would be 1000., days would be 86400000. The result can also be nothing if the variable has no time units.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.unlimited-Tuple{CommonDataModel.AbstractDataset}","page":"Home","title":"CommonDataModel.unlimited","text":"CommonDatamodel.unlimited(ds::AbstractDataset)\n\nIterator of strings with the name of the unlimited dimension.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.varbyattrib-Tuple{Union{CommonDataModel.AbstractDataset, CommonDataModel.AbstractVariable}}","page":"Home","title":"CommonDataModel.varbyattrib","text":"varbyattrib(ds, attname = attval)\n\nReturns a list of variable(s) which has the attribute attname matching the value attval in the dataset ds. The list is empty if the none of the variables has the match. The output is a list of CFVariables.\n\nExamples\n\nLoad all the data of the first variable with standard name \"longitude\" from the NetCDF file results.nc.\n\njulia> ds = NCDataset(\"results.nc\", \"r\");\njulia> data = varbyattrib(ds, standard_name = \"longitude\")[1][:]\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.variable-Tuple{CommonDataModel.AbstractDataset, Union{AbstractString, Symbol}}","page":"Home","title":"CommonDataModel.variable","text":"CommonDataModel.variable(ds::AbstractDataset,variablename::SymbolOrString)\n\nReturn the variable with the name variablename from the data set ds.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.varnames-Tuple{CommonDataModel.AbstractDataset}","page":"Home","title":"CommonDataModel.varnames","text":"CommonDataModel.varnames(ds::AbstractDataset)\n\nReturn an iterable of all the variable name.\n\n\n\n\n\n","category":"method"},{"location":"#CommonDataModel.@select-Tuple{Any, Any}","page":"Home","title":"CommonDataModel.@select","text":"vsubset = CommonDataModel.@select(v,expression)\ndssubset = CommonDataModel.@select(ds,expression)\n\nReturn a subset of the variable v (or dataset ds) satisfying the condition expression as a view. The condition has the following form:\n\ncondition₁ && condition₂ && condition₃ ... conditionₙ\n\nEvery condition should involve a single 1D variable (typically a coordinate variable, referred as coord below). If v is a variable, the related 1D variable should have a shared dimension with the variable v. All local variables need to have a $ prefix (see examples below). This macro is experimental and subjected to change.\n\nEvery condition can either perform:\n\na nearest match: coord ≈ target_coord (for ≈ type \\approx followed by the TAB-key). Only the data corresponding to the index closest to target_coord is loaded.\na nearest match with tolerance: coord ≈ target_coord ± tolerance. As before, but if the difference between the closest value in coord and target_coord is larger (in absolute value) than tolerance, an empty array is returned.\na condition operating on scalar values. For example, a condition equal to 10 <= lon <= 20 loads all data with the longitude between 10 and 20 or abs(lat) > 60 loads all variables with a latitude north of 60° N and south of 60° S (assuming that the has the 1D variables lon and lat for longitude and latitude).\n\nOnly the data which satisfies all conditions is loaded. All conditions must be chained with an && (logical and). They should not contain additional parenthesis or other logical operators such as || (logical or).\n\nTo convert the view into a regular array one can use collect, Array or regular indexing. As in julia, views of scalars are wrapped into a zero dimensional arrays which can be dereferenced by using []. Modifying a view will modify the underlying file (if the file is opened as writable, otherwise an error is issued).\n\nAs for any view, one can use parentindices(vsubset) to get the indices matching a select query.\n\nExamples\n\nCreate a sample file with random data:\n\nusing NCDatasets, Dates\nfname = \"sample_file.nc\"\nlon = -180:180\nlat = -90:90\ntime = DateTime(2000,1,1):Day(1):DateTime(2000,1,3)\nSST = randn(length(lon),length(lat),length(time))\n\nds = NCDataset(fname,\"c\")\ndefVar(ds,\"lon\",lon,(\"lon\",));\ndefVar(ds,\"lat\",lat,(\"lat\",));\ndefVar(ds,\"time\",time,(\"time\",));\ndefVar(ds,\"SST\",SST,(\"lon\",\"lat\",\"time\"));\n\n\n# load by bounding box\nv = NCDatasets.@select(ds[\"SST\"],30 <= lon <= 60 && 40 <= lat <= 90)\n\n# substitute a local variable in condition using $\nlonr = (30,60) # longitude range\nlatr = (40,90) # latitude range\n\nv = NCDatasets.@select(ds[\"SST\"],$lonr[1] <= lon <= $lonr[2] && $latr[1] <= lat <= $latr[2])\n\n# You can also select based on `ClosedInterval`s from `IntervalSets.jl`.\n# Both 30..60 and 65 ± 25 construct `ClosedInterval`s, see their documentation for details.\n\nlon_interval = 30..60\nlat_interval = 65 ± 25\nv = NCDatasets.@select(ds[\"SST\"], lon ∈ $lon_interval && lat ∈ $lat_interval)\n\n# get the indices matching the select query\n(lon_indices,lat_indices,time_indices) = parentindices(v)\n\n# get longitude matchting the select query\nv_lon = v[\"lon\"]\n\n# find the nearest time instance\nv = NCDatasets.@select(ds[\"SST\"],time ≈ DateTime(2000,1,4))\n\n# find the nearest time instance but not earlier or later than 2 hours\n# an empty array is returned if no time instance is present\n\nv = NCDatasets.@select(ds[\"SST\"],time ≈ DateTime(2000,1,3,1) ± Hour(2))\n\nclose(ds)\n\nAny 1D variable with the same dimension name can be used in @select. For example, if we have a time series of temperature and salinity, the temperature values can also be selected based on salinity:\n\n# create a sample time series\nusing NCDatasets, Dates\nfname = \"sample_series.nc\"\ntime = DateTime(2000,1,1):Day(1):DateTime(2009,12,31)\nsalinity = randn(length(time)) .+ 35\ntemperature = randn(length(time))\n\nNCDataset(fname,\"c\") do ds\n    defVar(ds,\"time\",time,(\"time\",));\n    defVar(ds,\"salinity\",salinity,(\"time\",));\n    defVar(ds,\"temperature\",temperature,(\"time\",));\nend\n\nds = NCDataset(fname)\n\n# load all temperature data from January where the salinity is larger than 35.\nv = NCDatasets.@select(ds[\"temperature\"],Dates.month(time) == 1 && salinity >= 35)\n\n# this is equivalent to\nv2 = ds[\"temperature\"][findall(Dates.month.(time) .== 1 .&& salinity .>= 35)]\n\n@test v == v2\nclose(ds)\n\nnote: Note\nFor optimal performance, one should try to load contiguous data ranges, in particular when the data is loaded over HTTP/OPeNDAP.\n\n\n\n\n\n","category":"macro"}]
}
