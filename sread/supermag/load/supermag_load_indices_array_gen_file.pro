;+
; Generate the CDF to hold supermag data.
;-

pro supermag_load_indices_array_gen_file, input_time_range, filename=file

    time_range = time_double(input_time_range)
    date = time_range[0]
    secofday = constant('secofday')
    date = date-(date mod secofday)

    cdf_touch, file

    gatts = dictionary($
        'TEXT', 'Supermag data saved through the official API', $
        'HTTP_LINK', 'https://supermag.jhuapl.edu/mag/?fidelity=low&tab=api' )
    cdf_save_setting, gatts, filename=file

    time_var = 'time'
    time_step = 60d
    ntime = secofday/time_step
    times = date+smkarthm(0,secofday,ntime,'n')
    vatts = dictionary($
        'VAR_TYPE', 'metadata', $
        'UNITS', 'sec', $
        'VAR_NOTES', 'unix time' )
    cdf_save_var, time_var, filename=file, value=times
    cdf_save_setting, vatts, varname=time_var, filename=file

end
