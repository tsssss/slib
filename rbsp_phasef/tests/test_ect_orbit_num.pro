time_range = time_double(['2019-01-01','2020-01-01'])

foreach probe, ['a','b'] do begin
    prefix = 'rbsp'+probe+'_'
    var = prefix+'orbit_num'
    if check_if_update(var, time_range) then begin
        rbsp_efw_phasef_read_orbit_num, time_range, probe=probe
    endif
    
    var = prefix+'dis'
    if check_if_update(var, time_range) then begin
        rbsp_read_orbit, time_range, probe=probe
        common_times = make_bins(time_range, 60)
        dis = snorm(get_var_data(prefix+'r_gse', at=common_times))
        store_data, var, common_times, dis
    endif
endforeach

end