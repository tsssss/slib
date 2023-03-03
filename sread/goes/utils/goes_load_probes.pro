function goes_load_probes, input_time_range

    valid_range_info = goes_valid_range_info()
    probes = (valid_range_info.keys()).toarray()
    time_ranges = (valid_range_info.values()).toarray()
    time_range = time_double(input_time_range)
    index = where(time_ranges[*,0] le max(time_range) and time_ranges[*,1] ge min(time_range), count)
    if count eq 0 then return, !null
    return, probes[index]

end


time_range = ['2013-01-01','2013-01-03']
probes = goes_load_probes(time_range)
end