using FCSFiles
using FileIO
using Test

project_root = dirname(dirname(@__FILE__))
testdata_dir = joinpath(project_root, "test", "fcsexamples")

if !isdir(testdata_dir)
    run(`git -C $(joinpath(project_root, "test")) clone https://github.com/tlnagy/fcsexamples.git --branch main --depth 1`)
else
    run(`git -C $testdata_dir fetch`)
    # for reproducibility we should use hard reset
    run(`git -C $testdata_dir reset --hard origin/main`)
    run(`git -C $testdata_dir pull`)
end

@testset "FCSFiles test suite" begin
    # test the loading of a large FCS file
    @testset "Loading of large FCS file" begin
        # load the large file
	flowrun = load(joinpath(testdata_dir, "Day 3.fcs"))
        @test length(flowrun) == 50
        @test length(getfield(flowrun, :params)) == 268
    end

    @testset "FlowSample size and length" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn) 
        @test size(flowrun) == (14, 100000)
        @test length(flowrun) == 14
    end

    @testset "FlowSample keys and haskey" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        expected = [
            "G710-A", "FSC-H", "V545-A", "FSC-A", "G560-A", "Time",
            "SSC-A", "B515-A", "G610-A", "Event #", "R780-A",
            "G780-A", "V450-A", "G660-A",
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
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        for key in keys(flowrun)
            @test flowrun[key] == getfield(flowrun, :data)[key]
        end
    end

    @testset "Multiple channel access using String" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)
        channels = keys(flowrun)
        for (keyA, keyB) in zip(channels[1:end-1], channels[2:end])
            @test flowrun[[keyA, keyB]] == getfield(flowrun, :data)[[keyA, keyB]]
        end
    end

    @testset "Integer sample indexing as second dimension" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        idx = rand(1:size(flowrun, 2))
        @test getfield(flowrun, :data)[:, idx] == flowrun[:, idx]

        @test getfield(flowrun, :data)[:, begin] == flowrun[:, begin]
        
        @test getfield(flowrun, :data)[:, end] == flowrun[:, end]

        rng = range(sort(rand(1:size(flowrun, 2), 2))..., step=1)
        @test getfield(flowrun, :data)[:, rng] == flowrun[:, rng]
    end

    @testset "Mixed indexing with String and Integer" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        idx = rand(1:size(flowrun, 2))
        @test getfield(flowrun, :data)["SSC-A", idx] == flowrun["SSC-A", idx]

        @test getfield(flowrun, :data)[["SSC-A", "FSC-A"], idx] == flowrun[["SSC-A", "FSC-A"], idx]

        rng = range(sort(rand(1:size(flowrun, 2), 2))..., step=1)
        @test getfield(flowrun, :data)["SSC-A", rng] == flowrun["SSC-A", rng]
        
        @test getfield(flowrun, :data)[["SSC-A", "FSC-A"], rng] == flowrun[["SSC-A", "FSC-A"], rng]
    end

    @testset "Logical indexing in second dimension" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        idxs = rand(Bool, size(flowrun, 2))
        @test getfield(flowrun, :data)["SSC-A", idxs] == flowrun["SSC-A", idxs]
    end

    @testset "Convert to Matrix" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        @test Array(getfield(flowrun, :data)) == Array(flowrun)
    end

    @testset "Regression for reading FCS files" begin
        # should catch if changes to the parsing of the file introduce errors
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
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

    @testset "Iterating FlowSample" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        i = 1
        pass = true
        for x in flowrun
            pass = pass && x == flowrun[i]
            i = i + 1
        end
        @test pass
    end

    @testset "Loading float-encoded file" begin
        flowrun = load(joinpath(testdata_dir, "Applied Biosystems - Attune.fcs"))

        @test length(flowrun["SSC-A"]) == 22188
        @test flowrun["FSC-A"][2] == 244982.11f0
    end

    @testset "Loading Accuri file" begin
        flowrun = load(joinpath(testdata_dir, "Accuri - C6.fcs"))
        @test length(flowrun["SSC-A"]) == 63273
        @test flowrun["SSC-A"][2] == 370971
    end

    @testset "params throws deprecation warning" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        msg = "`flowrun.params` is deprecated and will be removed in a future release. Parameters can be accessed like any other member variable. E.g. `flowrun.par` or `flowrun.PAR`."
        @test_logs (:warn, msg) flowrun.params
    end

    @testset "data throws deprecation warning" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        msg = "`flowrun.data` is deprecated and will be removed in a future release. The data can be indexed, e.g. `flowrun[\"SSC-A\"]` or can be obtained as a matrix with `Array(flowrun)`."
        @test_logs (:warn, msg) flowrun.data
    end

    @testset "`param_lookup` for different versions of the param" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)
        pass = true
        
        for (key, value) in getfield(flowrun, :params)
            # exact name
            pass = pass && value == FCSFiles.param_lookup(flowrun, key)
            # with no $
            var = first(match(r"^\$?(.+)", key))
            pass = pass && value == FCSFiles.param_lookup(flowrun, var)
            # in lowercase
            pass = pass && value == FCSFiles.param_lookup(flowrun, lowercase(key))
            # in lowercase with no $
            pass = pass && value == FCSFiles.param_lookup(flowrun, lowercase(var))
        end
        @test pass
    end

    @testset "param access through `Base.getproperty`" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)
        pass = true

        for (key, value) in getfield(flowrun, :params)
            # bare usage
            pass = pass && value == getproperty(flowrun, Symbol(key))
            # with no $
            var = first(match(r"^\$?(.+)", key))
            pass = pass && value == getproperty(flowrun, Symbol(var))
            # in lowercase
            pass = pass && value == getproperty(flowrun, Symbol(lowercase(key)))
            # in lowercase with no $
            pass = pass && value == getproperty(flowrun, Symbol(lowercase(var)))
        end
        @test pass
        @test_throws "no field notthere" flowrun.notthere
    end

    @testset "property names give the names of the parameters" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)
        pass = true

        for key in keys(getfield(flowrun, :params))
            var = Symbol(lowercase(first(match(r"^\$?(.+)", key))))
            pass = pass && var in propertynames(flowrun)
        end
        @test pass

        @test :params in propertynames(flowrun, true)
        @test :data in propertynames(flowrun, true)
    end
end
