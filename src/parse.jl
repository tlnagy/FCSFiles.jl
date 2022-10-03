function parse_header(io)
    seekstart(io)
    rawversion = Array{UInt8}(undef, 6)
    read!(io, rawversion)
    version = String(rawversion)
    if "$version" != "FCS3.0" && version != "FCS3.1"
        @warn "$version files are not guaranteed to work"
    end
    seek(io, 10)
    # start, end positions of TEXT, DATA, and ANALYSIS sections
    offsets = Array{Int64}(undef, 6)

    for i in 1:6
        # offsets are encoded as ASCII strings
        raw_str = Array{UInt8}(undef, 8)
        read!(io, raw_str)
        offsets_str = String(raw_str)

        # the last two numbers are for the analysis segment
        # the analysis segment is facultative, although the bytes should
        # always be there
        # (FCS 3.1 ref at https://isac-net.org/page/Data-Standards)
        # some cytometers (BD Accuri) do not put the last two bytes
        # putting "0" bytes in their files is what other cytometers do
        # see github discussion:
        # https://github.com/tlnagy/FCSFiles.jl/pull/13#discussion_r985251676
        if isempty(lstrip(offsets_str)) && i>4
            offsets_str="0"
        end
        offsets[i] = parse(Int, strip(join(offsets_str)))
    end

    # DATA offsets are larger than 99,999,999bytes
    if offsets[3] == 0 && offsets[4] == 0
        text_mappings = parse_text(io, offsets[1], offsets[2])
        offsets[3] = parse(Int64, text_mappings["\$BEGINDATA"])
        offsets[4] = parse(Int64, text_mappings["\$ENDDATA"])
    end
    return offsets
end


function parse_text(io, start_text::Int, end_text::Int)
    seek(io, start_text)
    # TODO: Check for supplemental TEXT file
    raw_btext = Array{UInt8}(undef, end_text - start_text + 1)
    read!(io, raw_btext)
    raw_text = String(raw_btext)
    # initialize iterator, save&skip the delimiter
    delimiter, state = iterate(raw_text)

    # container for the results
    text_mappings = Dict{String, String}()

    while iterate(raw_text, state) !== nothing
        # grab key and ignore escaped delimiters
        key, state = grab_word(raw_text, state, delimiter)

        # grab value and ignore escaped delimiters
        value, state = grab_word(raw_text, state, delimiter)

        # FCS keywords are case insensitive so force everything to uppercase
        text_mappings[uppercase(key)] = value
    end
    text_mappings
end


function parse_data(io,
                    start_data::Int,
                    end_data::Int,
                    text_mappings::Dict{String, String})
    seek(io, start_data)

    # data type in FCS3.1 can be I (integer), F (float32), A (Ascii)
    if text_mappings["\$DATATYPE"] == "I"
        dtype = Int32
    elseif text_mappings["\$DATATYPE"] == "F"
        dtype = Float32
    else
        error("Only float and integer data types are implemented for now, the required .fcs file is using another number encoding.")
    end

    flat_data = Array{dtype}(undef, (end_data - start_data + 1) ÷ 4)
    read!(io, flat_data)
    endian_func = get_endian_func(text_mappings)
    map!(endian_func, flat_data, flat_data)

    n_params = parse(Int, text_mappings["\$PAR"])

    # data should be in multiples of `n_params` for list mode
    (mod(length(flat_data), n_params) != 0) && error("FCS file is corrupt. DATA and TEXT sections don't match.")

    data = Dict{String, Vector{dtype}}()

    for i in 1:n_params
        data[text_mappings["\$P$(i)N"]] = flat_data[i:n_params:end]
    end

    FlowSample(data, text_mappings)
end
