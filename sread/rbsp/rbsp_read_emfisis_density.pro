
pro rbsp_read_emfisis_density, time_range, probe=probe, errmsg=errmsg

    ; read 'rbspx_emfisis_density'.
    rbsp_read_emfisis, time_range, probe=probe, id='l4%density', errmsg=errmsg
    if errmsg ne '' then return
    
    prefix = 'rbsp'+probe+'_'
    var = prefix+'emfisis_density'
    add_setting, var, /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'cm!U-3!N', $
        'short_name', 'Density' )
    get_data, var, times
    time_step = 6
    uniform_time, var, time_step
    
end

time_range = time_double(['2015-02-17/22:00','2015-02-18/08:00'])
probe = 'a'
rbsp_read_emfisis_density, time_range, probe=probe
end