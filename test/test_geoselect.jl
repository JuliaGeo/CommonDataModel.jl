using GeoRegions
using NCDatasets
using PyPlot
using Missings
using CommonDataModel
using CommonDataModel: select

function geo_select(v,(coordnames,fun))
    dn = dimnames(v)
    
    coord = ntuple(length(coordnames)) do i
        coord_dn = dimnames(ds[coordnames[i]])

        reshape_size = ntuple(length(dn)) do j
            if dn[j] in coord_dn
                size(v,j)
            else
                1
            end
        end
        reshape(Array(ds[coordnames[i]]),reshape_size)
    end

    mask = fun.(coord...)

    ij = ntuple(length(coordnames)) do i
        otherdims = Tuple(filter(!=(i),1:length(coord)))
        mm = dropdims(any(mask,dims=otherdims),dims=otherdims)
        findfirst(mm):findlast(mm)
    end

    v_in = allowmissing(v[ij...])

    v_in[.!mask[ij...]] .= missing
    return v_in
end
    
name = "AR6_EAO"
geo_EAO = GeoRegion(name)

# local example file with the 2D global surface topography
fname = "/home/abarth/workspace/divaonweb-test-data/DivaData/Global/gebco_30sec_2.nc"
ds = NCDataset(fname);
v = ds["bat"];


# similar to filter(in(1:3),1:10)


coordnames = (:lon,:lat)

i = 1


C = @time Point2(-45,-7.5)
C in geo_EAO



function ingeo(geo)
    return (lon,lat) -> Point2(lon,lat) in geo
end


v_in = geo_select(v,(:lon,:lat) => ingeo(geo_EAO))

v_in = select(v,(:lon,:lat) => ingeo(geo_EAO))

pcolormesh(nomissing(v_in,NaN)')


v_in2 = geo_select(v,(:bat,) => (<)(-6000))

# selecting the data outside of an area is similar easy
# similar to filter(!in(1:3),1:10)

#v_out = geo_select(v,(:lon,:lat) => !in(geo_EAO))
