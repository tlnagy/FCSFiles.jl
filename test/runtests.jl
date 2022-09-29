using FCSFiles
using FileIO
using Test, HTTP

@testset "FCSFiles test suite" begin
    testdir = dirname(@__FILE__)
    # test loading an FCS 2.0 file
    @testset "Loading an FCS 2.0 file" begin
        # download the FCS 2.0 file
        # load the FCS 2.0 file
        fn = testdir * "/testdata/testFCS2.fcs"
        @test_throws Exception @test_warn "FSC2.0 files are not guaranteed to work" flowrun = load(fn)
    end

    # test the size of the file
    @testset "SSC-A size" begin
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        @test length(load(fn)["SSC-A"]) == 100000
    end

    # test that channels can be accessed in the expected way
    @testset "Channel access" begin
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        flowrun = load(fn)
        for key in keys(flowrun.data)
            @test flowrun[key] == flowrun.data[key]
        end
    end

    # test that multiple channels can be accessed in the expected way
    @testset "Multiple channel access" begin
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        flowrun = load(fn)
        channels = collect(keys(flowrun.data))
        for (keyA, keyB) in zip(channels[1:end-1], channels[2:end])
            @test flowrun[[keyA, keyB]] == Dict(keyA => flowrun.data[keyA], keyB => flowrun.data[keyB])
        end
    end

    # test that individual samples/events can indexed
    @testset "Sample indexing " begin
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        flowrun = load(fn)

        idx = rand(1:length(flowrun))
        expected = Dict(k => flowrun.data[k][idx] for k in keys(flowrun.data))
        @test expected == flowrun[idx]
    end

    # test that collections of samples/events can indexed
    @testset "Samples indexing " begin
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        flowrun = load(fn)

        idxs = rand(1:length(flowrun["SSC-A"]), 256)
        expected = Dict(k => flowrun.data[k][idxs] for k in keys(flowrun.data))
        @test expected == flowrun[idxs]
    end
end
