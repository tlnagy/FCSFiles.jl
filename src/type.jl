struct FlowSample{T}
    data::Dict{String, Vector{T}}
    params::Dict{String, String}
end

const opt_params = [
("Machine", "\$CYT"),
("Begin Time", "\$BTIM"),
("End Time", "\$ETIM"),
("Date", "\$DATE"),
("File", "\$FIL"),
("Volume run", "\$VOL")
]


function Base.show(io::IO, f::FlowSample)
    spacing = " "^4
    print(io, typeof(f))

    for pair in opt_params
        if haskey(f.params, pair[2])
            print(io, "\n", spacing, "$(pair[1]): $(f.params[pair[2]])")
        end
    end
    print(io, "\n", spacing, "Axes:")
    n_params = parse(Int, f.params["\$PAR"])
    for i in 1:n_params
        print(io, "\n", spacing, spacing, "$(f.params["\$P$(i)N"])")
        if haskey(f.params, "\$P$(i)S")
            print(io, " ($(f.params["\$P$(i)N"]))")
        end
    end
end

# Implement most important parts of Dict interface
Base.length(f::FlowSample)  = length(f.data)
Base.haskey(f::FlowSample, x) = haskey(f.data, x)
Base.getindex(f::FlowSample, key) = f.data[key]
Base.keys(f::FlowSample) = keys(f.data)
Base.values(f::FlowSample) = values(f.data)
Base.iterate(iter::FlowSample) = Base.iterate(iter.data)
Base.iterate(iter::FlowSample, state) = Base.iterate(iter.data, state)
