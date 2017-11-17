using FCS
using FileIO
using Base.Test

flowrun = load("testdata/BD-FACS-Aria-II.fcs")

@test length(flowrun["SSC-A"]) == 100000
