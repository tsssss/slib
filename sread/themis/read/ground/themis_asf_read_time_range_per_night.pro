
function themis_asf_read_time_range_per_night, input_time_range, site=site, find_closest=find_closest

    file_times = themis_asf_read_file_times_per_night(input_time_range, site=site, find_closest=find_closest)
    if n_elements(file_times) eq 0 then return, !null

    time_var = 'range_epoch'
    time_range = dblarr(2)
    foreach file_time, minmax(file_times), id do begin
        file = themis_load_asi(file_time, site=site, id='l1%asf')
        epr = cdf_read_var(time_var, filename=file)
        time_range[id] = convert_time(epr[id], from='epoch', to='unix')
    endforeach

    return, time_range

end

test_times = make_bins(time_double(['2015-09-28','2015-09-29']), 3600)
site = 'gbay'

foreach time, test_times do begin
    time_range = themis_asf_read_time_range_per_night(time, site=site)
    
    print, ''
    print, time_string(time)
    print, ''
    if n_elements(time_range) ne 2 then continue
    print, time_string(time_range)
    wait, 2
endforeach
end