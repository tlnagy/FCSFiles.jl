using FCSFiles
using FileIO
using Test, HTTP

@testset "FCSFiles test suite" begin
    testdir = dirname(@__FILE__)
    @testset "Loading an FCS 2.0 file" begin
        # download the FCS 2.0 file
        # load the FCS 2.0 file
        fn = testdir * "/testdata/testFCS2.fcs"
        @test_throws Exception @test_warn "FSC2.0 files are not guaranteed to work" flowrun = load(fn)
    end

    @testset "FlowSample size and length" begin
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        flowrun = load(fn)
        @test size(flowrun) == (14, 100000)
        @test length(flowrun) == 14
    end

    @testset "FlowSample keys and haskey" begin
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        expected = [
            "G710-A", "FSC-H", "V545-A", "FSC-A", "G560-A", "Time", "SSC-A", "B515-A", "G610-A",
            "Event #", "R780-A", "G780-A", "V450-A", "G660-A",
        ]
        flowrun = load(fn)
        
        for channel in expected
            @test haskey(flowrun, channel)
        end

        @test all(x in keys(flowrun) for x in expected)
    end

    # AxisArray already has tests, here we are just checking that
    # relevant methods get forwarded to their AxisArray implementation
    @testset "Channel access using String" begin
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        flowrun = load(fn)

        for key in keys(flowrun)
            @test flowrun[key] == flowrun.data[key]
        end
    end

    @testset "Multiple channel access using String" begin
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        flowrun = load(fn)
        channels = keys(flowrun)
        for (keyA, keyB) in zip(channels[1:end-1], channels[2:end])
            @test flowrun[[keyA, keyB]] == flowrun.data[[keyA, keyB]]
        end
    end

    @testset "Integer sample indexing as second dimension" begin
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        flowrun = load(fn)

        idx = rand(1:size(flowrun)[2])
        @test flowrun.data[:, idx] == flowrun[:, idx]

        @test flowrun.data[:, begin] == flowrun[:, begin]
        
        @test flowrun.data[:, end] == flowrun[:, end]

        rng = range(sort(rand(1:size(flowrun)[2], 2))..., step=1)
        @test flowrun.data[:, rng] == flowrun[:, rng]
    end

    @testset "Mixed indexing with String and Integer" begin
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        flowrun = load(fn)

        idx = rand(1:size(flowrun)[2])
        @test flowrun.data["SSC-A", idx] == flowrun["SSC-A", idx]

        @test flowrun.data[["SSC-A", "FSC-A"], idx] == flowrun[["SSC-A", "FSC-A"], idx]

        rng = range(sort(rand(1:size(flowrun)[2], 2))..., step=1)
        @test flowrun.data["SSC-A", rng] == flowrun["SSC-A", rng]
        
        @test flowrun.data[["SSC-A", "FSC-A"], rng] == flowrun[["SSC-A", "FSC-A"], rng]
    end

    @testset "Logical indexing in second dimension" begin
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        flowrun = load(fn)

        idxs = rand(Bool, size(flowrun)[2])
        @test flowrun.data["SSC-A", idxs] == flowrun["SSC-A", idxs]
    end

    @testset "Convert to Matrix" begin
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        flowrun = load(fn)

        @test Array(flowrun.data) == Array(flowrun)
    end

    @testset "Regression for reading FCS files" begin
        # should catch if changes to the parsing of the file introduce errors
        fn = testdir * "/testdata/BD-FACS-Aria-II.fcs"
        flowrun = load(fn)

        checkpoints = [
            ("SSC-A", 33),
            ("G610-A", 703),
            ("Event #", 382),
            ("FSC-A", 15),
            ("Time", 1),
            ("V450-A", 9938)
        ]

        expected = [585.006f0, 993.2587f0, 3810.0f0, 131008.0f0, 0.0f0, 472.9652f0]

        for (checkpoint, value) in zip(checkpoints, expected)
            @test flowrun[checkpoint[1]][checkpoint[2]] == value
        end
    end
end
