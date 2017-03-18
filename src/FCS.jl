module FCS

using FileIO

include("type.jl")
include("utils.jl")
include("parse.jl")

export load, FlowSample

try
    add_format(format"FCS", "FCS", [".fcs"])
end

function FileIO.load(f::File{format"FCS"})
    open(f) do io
        offsets = parse_header(io)

        text_mappings = parse_text(io, offsets[1], offsets[2])
        verify_text(text_mappings)

        return parse_data(io, offsets[3], offsets[4], text_mappings)
    end
end

end # module
