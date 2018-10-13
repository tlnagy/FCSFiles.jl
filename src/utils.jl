# These are keywords present in the TEXT section that are guaranteed by the spec
const required_keywords = [
    "\$BEGINANALYSIS", # Byte-offset to the beginning of the ANALYSIS segment.
    "\$BEGINDATA", # Byte-offset to the beginning of the DATA segment.
    "\$BEGINSTEXT", # Byte-offset to the beginning of a supplemental TEXT segment.
    "\$BYTEORD", # Byte order for data acquisition computer.
    "\$DATATYPE", # Type of data in DATA segment (ASCII, integer, floating point).
    "\$ENDANALYSIS", # Byte-offset to the last byte of the ANALYSIS segment.
    "\$ENDDATA", # Byte-offset to the last byte of the DATA segment.
    "\$ENDSTEXT", # Byte-offset to the last byte of a supplemental TEXT segment.
    "\$MODE", # Data mode (list mode - preferred, histogram - deprecated).
    "\$NEXTDATA", # Byte offset to next data set in the file.
    "\$PAR", # Number of parameters in an event.
    "\$PnB", # Number of bits reserved for parameter number n.
    "\$PnE", # Amplification type for parameter n.
    "\$PnN", # Short name for parameter n.
    "\$PnR", # Range for parameter number n.
    "\$TOT"  # Total number of events in the data set.
    ]


"""
    grab_word(iter, state, delimiter) -> word, state

Grabs the next word from the iterator `iter`. Takes care to handle escaped
delimiters specified by `delimiter`. Returns a string containing the word
and the state of the iterator.
"""
function grab_word(iter, state, delimiter::Char)
    word = Char[]
    prev = ' '
    iter_result = iterate(iter, state)
    while iter_result !== nothing
        i, state = iter_result

        # only add character if the current and previous are both
        # delimiters (i.e. escaped) or neither are
        if !xor((prev == delimiter), (i == delimiter))
            push!(word, i)
            prev = i
        else
            break
        end
        iter_result = iterate(iter, state)
    end
    join(word), state
end


"""
    verify_text(text_mappings) -> Void

Checks that all required keywords are present in the text_mapping dictionary
returned by `parse_text`
"""
function verify_text(text_mappings::Dict{String, String})
    # get all parameterized keywords $P1N, $P2N, etc
    is_param = [occursin("n", keyword) for keyword in required_keywords]

    # verify that all non-parameterized keywords are present in the mapping
    for non_param in required_keywords[.~is_param]
        if !haskey(text_mappings, non_param)
            error("FCS file is corrupted. It is missing required keyword $non_param in its TEXT section")
        end
    end

    # TODO: Add support for modes other than list
    (text_mappings["\$MODE"] != "L") && error("Non list mode FCS files are not supported yet")

    n_params = parse(Int, text_mappings["\$PAR"])

    for params in required_keywords[is_param]
        for i in 1:n_params
            if !haskey(text_mappings, replace(params, "n"=>i))
                error("FCS file is corrupted. It is missing required keyword $non_param in its TEXT section")
            end
        end
    end
end

function get_endian_func(text_mappings::Dict{String, String})
    byte_order = text_mappings["\$BYTEORD"]
    if byte_order == "1,2,3,4" # least significant byte first
        return ltoh
    elseif byte_order == "4,3,2,1" # most significant byte first
        return ntoh
    else
        error("FCS file is malformed. '$(byte_order)' is not a valid byte order.")
    end


end
