using FCSFiles
using FileIO
using Test

flowrun = load("testdata/BD-FACS-Aria-II.fcs")

@test length(flowrun["SSC-A"]) == 100000
