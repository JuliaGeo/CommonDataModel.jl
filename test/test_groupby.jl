using Test
using Dates
#using NCDatasets
using Statistics

using CommonDataModel
using CommonDataModel:
    @groupby,
    name,
    GroupedVariable,
    ReducedGroupedVariable,
    _array_selectdim_indices,
    _dest_indices,
    _dim_after_getindex,
    _indices,
    groupby


#include("memory_dataset.jl");

#TDS = NCDatasets.NCDataset
TDS = MemoryDataset

# test helper functions

@test _dest_indices(1,1,(:,:,:)) == (1,:,:)
@test _dest_indices(2,1,(:,:,:)) == (:,1,:)
@test _dest_indices(3,1,(:,:,:)) == (:,:,1)
@test _dest_indices(3,1,(1,:,:)) == (:,1)

@test _indices(1,12,1,(:,:,:)) == (12,1,1)
@test _indices(2,12,1,(:,:,:)) == (1,12,1)
@test _indices(2,12,1,(1,:,:)) == (12,1)

@test _indices(1,12,:,(:,:,:)) == (12,:,:)
@test _indices(1,1,:,(:,:,:)) == (1,:,:)

@test _array_selectdim_indices((),3,1:1,2,2,3) == (:,:,1:1)

@test _dim_after_getindex(0,:,:,:) == 3
@test _dim_after_getindex(0,1,1,1) == 0
@test _dim_after_getindex(0,:,1,:) == 2
@test _dim_after_getindex(0,[1,2],1,:) == 2

time = DateTime(2000,1,1):Day(10):DateTime(2012,1,1);
data = rand(Float32.(-9:99),10,11,length(time))
varname = "data"

fname = tempname()

TDS(fname,"c") do ds
    defVar(ds,"lon",1:size(data,1),("lon",))
    defVar(ds,"lat",1:size(data,2),("lat",))
    defVar(ds,"time",time,("time",))
    defVar(ds,"data",data,("lon","lat","time"))
    defVar(ds,"data2",data .+ 1,("lon","lat","time"))
end

ds = TDS(fname)

coordname = "time"
group_fun = time -> Dates.Month(time)

v = ds[varname]

for reduce_fun in (sum,mean,var,std,median,maximum)
    local data_by_class
    data_by_class_ref = cat(
        [reduce_fun(v[:,:,findall(Dates.month.(ds[coordname][:]) .== m)],dims=3)
         for m in 1:12]...,dims=3)

    for indices = [
        (:,:,:),
        (1:3,2:5,:),
        (1:3,2,:),
        (2,1:3,:),
        (1:3,2:6,2:6),
        (:,:,2),
        ]

        local data_by_class
        data_by_class = reduce_fun(groupby(ds[varname],:time => Dates.Month))[indices...]
        @test data_by_class ≈ data_by_class_ref[indices...]
        @test size(data_by_class) == size(data_by_class_ref[indices...])
    end
end


# sum of absolute values
sum_abs = cat([sum(abs.(ds[varname][:,:,:][:,:,findall(Dates.month.(ds[coordname][:]) .== m)]),dims=3)
          for m in 1:12]...,dims=3)

gv = groupby(ds[varname],:time => Dates.Month)

absp(x) = abs.(x)
gd = groupby(ds[:data],:time => Dates.Month);

@test sum(absp.(gd))[:,:,:] == sum_abs


d_sum = cat([sum(ds[varname][:,:,:][:,:,findall(Dates.month.(ds[coordname][:]) .== m)],dims=3)
                 for m in 1:12]...,dims=3)


gd = groupby(ds["data"],"time" => Dates.Month)
month_sum = sum(gd);
@test month_sum[:,:,:] == d_sum


gd = groupby(ds[:data],:time => Dates.Month)
month_sum = sum(gd);
@test month_sum[:,:,:] == d_sum



gr = month_sum
f = gr.reduce_fun

mysum(x; dims=nothing) = sum(x,dims=dims)
mysum(gv::GroupedVariable) = reduce(mysum,gv)

gd = groupby(ds[:data],:time => Dates.Month);
month_sum = mysum(gd);
@test month_sum[:,:,:] == d_sum

month_sum = reduce(mysum,gd);
@test month_sum[:,:,:] == d_sum


# test macro
gd = @groupby(v,Dates.Month(time));

@test ndims(gd) == 1
@test size(gd) == (12,)

gr = sum(gd)

@test ndims(gr) == 3
@test size(gr) == (10,11,12)

@test sum(absp.(gd))[:,:,:] == sum_abs

gm = sum(gd);
@test gm[:,:,:] == d_sum

fun_call_groupby(v) = sum(@groupby(v,Dates.Month(time)));
gm = fun_call_groupby(v)
@test gm[:,:,:] == d_sum


gm = mean(@groupby(v,time >= DateTime(2001,1,1)));
gm2 = mean(v[:,:,findall(v["time"][:] .>= DateTime(2001,1,1))],dims=3)

@test gm[:,:,:][:,:,2] ≈ gm2
@test gm[:,:,2:2] ≈ gm2[:,:,1:1]
@test gm[:,:,2] ≈ gm2

gm = @groupby(v,time >= DateTime(2001,1,1)) |> mean |> Array
@test gm[:,:,2] ≈ gm2

# broadcast of mean

C = v .- mean(@groupby(v,Dates.Month(time)));
B = Array(mean(@groupby(v,Dates.Month(time))))

Cref = similar(v)

classes = Dates.Month.(v["time"][:])
unique_class = unique(classes)
for k = 1:length(unique_class)
    local indices
    indices = findall(==(unique_class[k]),classes)
    Cref[:,:,indices] = v[:,:,indices] .- B[:,:,k:k]
end

@test C ≈ Cref

Cn = mean(@groupby(v,Dates.Month(time))) .- v
@test Cn ≈ -Cref

# parent dataset

gr = mean(@groupby(v,Dates.Month(time)))

gds = dataset(gr);
@test Set(keys(gds)) == Set(keys(ds))
@test variable(gds,"data")[:,:,:] ≈ gr[:,:,:]


gr2 = mean(@groupby(ds["data2"],Dates.Month(time)))
@test gds["data"][:,:,:] ≈ gr[:,:,:]
@test gds["data2"][:,:,:] ≈ gr2[:,:,:]
@test gr2["data2"][:,:,:] ≈ gr2[:,:,:]


@test gds["lon"][:] == 1:size(data,1)
io = IOBuffer()
show(io,"text/plain",gr)
@test occursin("array", String(take!(io)))

io = IOBuffer()
show(io,"text/plain",gv)
@test occursin("array", String(take!(io)))

@test eltype(gv) == Array{Float32,3}
@test name(gr) == "data"
