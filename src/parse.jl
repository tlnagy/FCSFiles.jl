function parse_header(io)
    seekstart(io)
    version = String(read(io, UInt8, 6))
    if "$version" != "FCS3.0" && version != "FCS3.1"
        warn("$version files are not guaranteed to work")
    end
    seek(io, 10)
    # start, end positions of TEXT, DATA, and ANALYSIS sections
    offsets = Array{Int64}(6)
    for i in 1:6
        # offsets are encoded as ASCII strings
        raw_str = String(read(io, UInt8, 8))
        offsets[i] = parse(Int, strip(join(raw_str)))
    end

    # DATA offsets are larger than 99,999,999bytes
    if offsets[3] == 0 && offsets[4] == 0
        error("Reading of larger FCS not yet implemented, see issues")
    end
    offsets
end


function parse_text(io, start_text::Int, end_text::Int)
    seek(io, start_text)
    # TODO: Check for supplemental TEXT file
    raw_text = String(read(io, UInt8, end_text - start_text + 1))
    delimiter = raw_text[1]

    text_mappings = Dict{String, String}()
    # initialize iterator
    prev, state = next(raw_text, start(raw_text))
    while !done(raw_text, state)
        i, state = next(raw_text, state)

        # found a new key, value pair
        if i == '$'
            # grab key and ignore escaped delimiters
            key, state = grab_word(raw_text, state, delimiter)
            # grab value and ignore escaped delimiters
            value, state = grab_word(raw_text, state, delimiter)
            # FCS keywords are case insensitive so force them uppercase
            text_mappings["\$"*uppercase(key)] = value
        end
        prev = i
    end
    text_mappings
end


function parse_data(io,
                    start_data::Int,
                    end_data::Int,
                    text_mappings::Dict{String, String})
    seek(io, start_data)
    # Add support for data types other than float
    (text_mappings["\$DATATYPE"] != "F") && error("Non float32 support not implemented yet. Please see github issues for this project.")

    flat_data = read(io, Float32, (end_data - start_data + 1) ÷ 4)
    endian_func = get_endian_func(text_mappings)
    map!(endian_func, flat_data)

    n_params = parse(Int, text_mappings["\$PAR"])

    # data should be in multiples of `n_params` for list mode
    (mod(length(flat_data), n_params) != 0) && error("FCS file is corrupt. DATA and TEXT sections don't match.")

    data = Dict{String, Vector{Float32}}()

    for i in 1:n_params
        data[text_mappings["\$P$(i)N"]] = flat_data[i:n_params:end]
    end

    FlowSample(data, text_mappings)
end
