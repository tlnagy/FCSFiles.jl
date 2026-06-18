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
    if text_mappings["\$DATATYPE"] == "I"
        intsize=get_int_size(text_mappings) # Check Int sizes
        uniinsize=unique(values(intsize)) # Extract all the unique int sizes
        if length(uniinsize) == 1 # If the columns are uniform in Int size
            unsize=Int(parse(Int,uniinsize[1])/8) # How many UInt8s does this cover
            # Read io into a UInt8 Buffer
            buf=read(io)
            # Get Endianness of data
            byte_order = text_mappings["\$BYTEORD"]
            # Shift bits based on the Endianness of said data and then convert to a UInt32 for reading. 
            if byte_order=="1,2,3,4"
                buf2=[UInt32(sum(UInt32(buf[i + j]) << (8 * j) for j in 0:(unsize - 1))) for i in 1:unsize:length(buf)] # Little Endian bit shifting - note: this is stored in the endianess of the system it is working in - Windows, Mac and Linux are generally Little Endian.
            elseif byte_order == "4,3,2,1"
                buf2=[UInt32(sum(UInt32(buf[i + j]) << (8 * (unsize - j - 1)) for j in 0:(unsize - 1))) for i in 1:unsize:length(buf)] # Big Endian bit shifting - note: this is stored in the endianess of the system it is working in - Windows, Mac and Linux are generally Little Endian.
            else
                error("Keyword \$BYTEORDER is different that expected.")
            end
            # Create new IO Buffer to put IO in.
            io_buffer=IOBuffer() 
            # Write the IO to the IOBuffer just created.
            write(io_buffer,buf2)
            # Find the start of the new io_buffer
            seekstart(io_buffer)
        else
            error("Uneven bit-width (not divisible by 8 or changing bit width between channels) is not implemented.") # Uneven maps not implemented.
        end
        dtype = Int32
    elseif text_mappings["\$DATATYPE"] == "F"
        dtype = Float32
    elseif text_mappings["\$DATATYPE"] == "D"
        dtype = Float64
    else
        error("Only float and integer data types are implemented for now, the required .fcs file is using another number encoding.")
    end

    
    # Use the regular io if float and allow any endian type.
    # If the io buffer is an integer array, read in the data in flat format and use ltoh ans this is what is defined by the system.
    if text_mappings["\$DATATYPE"] != "I"
        flat_data = Array{dtype}(undef, (end_data - start_data + 1) ÷ 4)
        read!(io, flat_data)
        endian_func = get_endian_func(text_mappings)
    else
        flat_data = Array{dtype}(undef, length(buf2))
        read!(io_buffer, flat_data)
        endian_func=ltoh # System defined 
    end
    map!(endian_func, flat_data, flat_data)

    n_params = parse(Int, text_mappings["\$PAR"])

    # data should be in multiples of `n_params` for list mode
    (mod(length(flat_data), n_params) != 0) && error("FCS file is corrupt. DATA and TEXT sections don't match.")

    datamatrix = Matrix{dtype}(undef, n_params, length(flat_data) ÷ n_params)
    rows = Vector{String}(undef, n_params)

    for i in 1:n_params
        rows[i] = text_mappings["\$P$(i)N"]
        datamatrix[i, :] = flat_data[i:n_params:end]
    end
    data = AxisArray(datamatrix, Axis{:param}(rows), Axis{:event}(1:size(datamatrix, 2)))
    FlowSample(data, text_mappings)
end
