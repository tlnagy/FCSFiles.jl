# FCSFiles

Add FileIO.jl integration for FCS files

| Stable release                                   | Repo status  |
|--------------------------------------------------|--------------|
| ![](https://juliahub.com/docs/FCSFiles/version.svg) | [![][ci-img]][ci-url] [![][codecov-img]][codecov-url] |

## Loading an FCSFile
FCS files can be loaded by using the FileIO interface.

```julia
julia> using FileIO

julia> flowrun = load("example.fcs")
FCS.FlowSample{Float32}
    Machine: LSRFortessa
    Begin Time: 14:12:03
    End Time: 14:12:25
    Date: 17-MAR-2017
    File: Specimen_001_Tube_002_002.fcs
    Axes:
        FSC-A
        FSC-H
        FSC-W
        SSC-A
        SSC-H
        SSC-W
        B_530-30-A
        Time
```

## Metadata
Once loaded the parameters of the FCS file are available as properties.

```
julia> flowrun.last_modified
"2019-Oct-03 15:35:15"

julia> flowrun.p1n
"FSC-A"
```

## Indexing
There are many ways to index into the FCS file. You can index the FCS file as a matrix (actually an `AxisArray`).

```
julia> flowrun[:, 1]
1-dimensional AxisArray{Float32,1,...} with axes:
    :param, ["FSC-A", "FSC-H", "SSC-A", "SSC-H", "B1-A", "B1-H", "B2-A", "B2-H", "HDR-CE", "HDR-SE"  …  "V2-A", "V2-H", "Y1-A", "Y1-H", "Y2-A", "Y2-H", "Y3-A", "Y3-H", "Y4-A", "Y4-H"]
And data, a 23-element Vector{Float32}:
 19.319384
 12.838199
 44.391308
 20.214031
  0.01834727
  0.72980446
 -0.25282443
  0.4430968
  ⋮
  0.54869235
 -0.027989198
  0.48970717
  4.498265
  5.900927
  0.02512901
  0.3956769
```

This retrieves the values of all the parameters for the first event in the FCS file.

Similarly you can get the values of a single parameter for all events.

```
julia> flowrun[1, :]
1-dimensional AxisArray{Float32,1,...} with axes:
    :event, 1:83562
And data, a 83562-element Vector{Float32}:
 19.319384
 22.961153
 36.157864
 30.91769
  5.644829
 14.188097
 34.42944
  4.4080987
  ⋮
 23.391977
 -4.813841
 -1.2413055
 11.075016
 13.712906
 23.54529
  5.740017
```

You can also take ranges of events.

```
julia> flowrun[1, end-99:end]
1-dimensional AxisArray{Float32,1,...} with axes:
    :event, 83463:83562
And data, a 100-element Vector{Float32}:
   4.576562
   2.553804
  10.608879
  -6.4025674
 -18.626959
   6.1649327
  24.049818
  21.735662
   ⋮
  23.391977
  -4.813841
  -1.2413055
  11.075016
  13.712906
  23.54529
   5.740017
```

If you know the name of a parameter you can use that name to index.

```
julia> flowrun["FSC-A"]
1-dimensional AxisArray{Float32,1,...} with axes:
    :event, 1:83562
And data, a 83562-element Vector{Float32}:
 19.319384
 22.961153
 36.157864
 30.91769
  5.644829
 14.188097
 34.42944
  4.4080987
  ⋮
 23.391977
 -4.813841
 -1.2413055
 11.075016
 13.712906
 23.54529
  5.740017
```

Or you can get multiple parameters at the same time.

```
julia> flowrun[["FSC-A", "FSC-H"]]
2-dimensional AxisArray{Float32,2,...} with axes:
    :param, ["FSC-A", "FSC-H"]
    :event, 1:83562
And data, a 2×83562 Matrix{Float32}:
 19.3194  22.9612   36.1579  30.9177  …  11.075    13.7129   23.5453   5.74002
 12.8382   3.40729  17.4995  14.0875      8.80171   5.29686  13.0893  11.3576
```

In general, any indexing that works with `AxisArray`s should work the same with FCS files.

## Plotting
Here is an example which constructs a 2D histogram visualisation of a FCS file.

```
julia> using Gadfly

julia> p = plot(x=flowrun["FSC-A"], y=flowrun["SSC-A"], Geom.histogram2d,
Guide.xlabel("FSC-A"), Guide.ylabel("SSC-A"), Coord.cartesian(xmin=0, ymin=0))

julia> draw(PNG("example.png", 10cm, 7cm, dpi=300), p)
```

![](example.png)

[ci-img]: https://github.com/tlnagy/FCSFiles.jl/workflows/CI/badge.svg
[ci-url]: https://github.com/tlnagy/FCSFiles.jl/actions

[codecov-img]: https://codecov.io/gh/tlnagy/FCSFiles.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/tlnagy/FCSFiles.jl
