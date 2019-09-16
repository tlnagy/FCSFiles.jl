using FCSFiles
using FileIO
using Test, HTTP

@testset "FCSFiles test suite" begin
    @testset "SSC-A size" begin
        flowrun = load("testdata/BD-FACS-Aria-II.fcs")

        @test length(flowrun["SSC-A"]) == 100000
    end

    # test the loading of a large FCS file
    @testset "Loading of large FCS file" begin
        # download the large FCS file
        cwd = pwd()
        cd(cwd*"/testdata")
        @info "Downloading large FCS file ..."
        io = open("testLargeFile.fcs", "w")
        r = HTTP.request("GET", "https://flowrepository.org/experiments/1177/fcs_files/113151/download", response_stream=io)
        close(io)
        cd(cwd)
        @info "Done."

        # load the large file
        flowrun = load("testdata/testLargeFile.fcs")
        @test length(flowrun.data) == 50
        @test length(flowrun.params) == 262

        # cleanup
        rm("testdata/testLargeFile.fcs", force=true)
        @info "Large file removed"
    end
end
