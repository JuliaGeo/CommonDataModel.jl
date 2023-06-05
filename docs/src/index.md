
## Data types

In order to implement a new dataset based `CommonDataModel.jl`
one has to create two types derived from:

1. [`AbstractVariable`](#CommonDataModel.AbstractVariable): a variable with named dimension and metadata
2. [`AbstractDataset`](#CommonDataModel.AbstractDataset): a collection of variable with named dimension, metadata and sub-groups. The sub-groups are also `AbstractDataset`.


`CommonDataModel.jl` also provides a type `CFVariable` which wraps a type derived from `AbstractVariable` and applies the scaling described in
[`cfvariable`](#CommonDataModel.cfvariable).

Overview of methods:

|            | get names                                     | get values                              | write / set value                        |
|------------|-----------------------------------------------|-----------------------------------------|-------------------------------------------|
| Dimensions | [`dimnames`](#CommonDataModel.dimnames)       | [`dim`](#CommonDataModel.dim)           | [`defDim`](#CommonDataModel.defDim)       |
| Attributes | [`attribnames`](#CommonDataModel.attribnames) | [`attrib`](#CommonDataModel.attrib)     | [`defAttrib`](#CommonDataModel.defAttrib) |
| Variables  | [`varnames`](#CommonDataModel.varname   s)    | [`variable`](#CommonDataModel.variable) | [`defVar`](#CommonDataModel.defVar)       |
| Groups     | [`groupnames`](#CommonDataModel.groupnames)   | [`group`](#CommonDataModel.group)       | [`defGroup`](#CommonDataModel.defGroup)   |

For read-only datasets, the methods in last column are not implemented.

```@autodocs
Modules = [CommonDataModel]
```
