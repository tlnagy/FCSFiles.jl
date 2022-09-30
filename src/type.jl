struct FlowSample{T<:Number, I<:AbstractVector{Int}}
    data::AxisArray{T, 2, Matrix{T}, Tuple{Axis{:row, Vector{String}}, Axis{:col, I}}}
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

Base.size(f::FlowSample) = size(f.data)
Base.length(f::FlowSample)  = size(f)[1]

Base.keys(f::FlowSample) = f.data.axes[1]
Base.haskey(f::FlowSample, x) = x in keys(f)
Base.values(f::FlowSample) = [f.data[key] for key in keys(f)]

Base.getindex(f::FlowSample, args...) = getindex(f.data, args...)
Base.axes(f::FlowSample) = map(Base.OneTo, size(f))
Base.axes(f::FlowSample, i::Int) = Base.axes(f)[i]

Base.iterate(iter::FlowSample) = Base.iterate(iter.data)
Base.iterate(iter::FlowSample, state) = Base.iterate(iter.data, state)

Base.Array(f::FlowSample) = Array(f.data)
