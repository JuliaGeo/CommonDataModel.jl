
## Abstract types

Overview of methods

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
