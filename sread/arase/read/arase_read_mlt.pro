;+
; Read Arase MLT. Save as 'arase_mlt'.
;-

function arase_read_mlt, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name

    prefix = 'arase_'
    var = prefix+'mlt'
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    r_sm_var = arase_read_orbit(time_range, probe=probe, errmsg=errmsg, coord='sm')
    if errmsg ne '' then return, var

    r_sm = get_var_data(r_sm_var, times=times)
    mlt = pseudo_mlt(r_sm)
    store_data, var, times, mlt

    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'MLT', $
        'unit', 'h' )
    return, var

end

time_range = time_double(['2017-06-13','2017-06-14'])
time_range = time_double(['2018-04-11','2018-04-12'])
time_range = time_double(['2018-12-25','2018-12-26'])
vars = list()
vars.add, arase_read_mlt(time_range)
foreach probe, ['a','b'] do begin
    vars.add, rbsp_read_mlt(time_range, probe=probe)
endforeach
vars = vars.toarray()

time_step = 60
common_times = make_bins(time_range, time_step)
foreach var, vars do begin
    interp_time, var, common_times
endforeach
mlt_var = stplot_merge(vars, output='mlt_combo', labels=['Arase','RBSP-'+['A','B']], colors=constant('rgb'))
tplot, mlt_var, trange=time_range
end