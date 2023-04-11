import CommonDataModel as CDM

struct DummyEmptyDataset <: CDM.AbstractDataset
end

dd = DummyEmptyDataset();
@test CDM.dimnames(dd) == ()
@test_throws Exception CDM.dim(dd,"does_not_exist")
@test_throws Exception CDM.defDim(dd,"does_not_exist",1)

@test CDM.attribnames(dd) == ()
@test_throws Exception CDM.attrib(dd,"does_not_exist")
@test_throws Exception CDM.defAttrib(dd,"does_not_exist",1)

@test CDM.varnames(dd) == ()
@test_throws Exception CDM.variable(dd,"does_not_exist")
@test_throws Exception CDM.defVar(dd,"does_not_exist",Int32,())

@test CDM.path(dd) == ""

@test CDM.groupnames(dd) == ()
# not available in julia 1.6
#@test_throws "no group" CDM.group(dd,"does_not_exist")
#@test_throws "unimplemented" CDM.defGroup(dd,"does_not_exist")
@test_throws Exception CDM.group(dd,"does_not_exist")
@test_throws Exception CDM.defGroup(dd,"does_not_exist")
