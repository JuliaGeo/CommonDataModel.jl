
## Abstract types

In order to implement a new dataset based `CommonDataModel.jl`
one has to create two types derived from:
1 .`AbstractVariable`: a variable with named dimension and metadata
2. `AbstractDataset`: a collection of variable with named dimension, metadata and sub-groups. The sub-groups are also `AbstractDataset`.


Overview of methods:

|            | get names     | get value  | write / set value |
|------------|---------------|------------|-------------------|
| Dimensions | `dimnames`    | `dim`      | `defDim`          |
| Attributes | `attribnames` | `attrib`   | `defAttrib`       |
| Variables  | `varnames`    | `variable` | `defVar`          |
| Groups     | `groupnames`  | `group`    | `defGroup`        |

For read-only datasets, the methods in last column are not implemented.

```@autodocs
Modules = [CommonDataModel]
```
