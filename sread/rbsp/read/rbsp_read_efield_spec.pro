;+
; Read E field spec.
;-

function rbsp_read_efield_spec, input_time_range, probe=probe, errmsg=errmsg, $
    get_name=get_name, update=update, suffix=suffix

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    id = 'e'
    if n_elements(suffix) eq 0 then suffix = ''
    out_var = prefix+id+'_spec'+suffix
    if keyword_set(get_name) then return, out_var
    time_range = time_double(input_time_range)
    if keyword_set(update) then del_data, out_var
    if ~check_if_update(out_var, time_range) then return, out_var


;---Read spec in different freq ranges.
    spec_vars = list()
    spec_vars.add, rbsp_read_wave_spec_mhz(time_range, probe=probe)
    spec_vars.add, rbsp_read_wave_spec_khz(time_range, probe=probe, id=id)
    spec_vars.add, rbsp_read_wave_spec_hz(time_range, probe=probe, id=id)
    freq_ranges = [[1e4,5e4],[10,1e4],[0.1,10]]

;---Combine them.
    yrange = [0.1,5e4]
    dfreq = 1.15
    freqs = smkgmtrc(yrange[0],yrange[1],dfreq, 'dx')
    nfreq = n_elements(freqs)
    xrange = time_range
    time_step = 1d
    common_times = make_bins(xrange,time_step)
    ntime = n_elements(common_times)
    specs = fltarr(ntime,nfreq)
    foreach var, spec_vars, var_id do begin
        data = get_var_data(var, vals, at=common_times, limits=lim)
        freq_range = freq_ranges[*,var_id]
        index = where_pro(freqs, '[)', freq_range, count=count)
        if count eq 0 then message, 'Inconsistency ...'
        specs[*,index] = transpose(sinterpol(transpose(data),vals,freqs[index]))
    endforeach
    unit = lim.unit
    zrange = [1e-8,1e1]
    
    log_ytickv = make_bins(minmax(alog10(yrange)),1,inner=1)
    ytickv = 10d^log_ytickv
    ytickname = get_short_log_tickname(log_ytickv)
    yminor = 9
    
    store_data, out_var, common_times, specs, freqs
    add_setting, out_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'no_interp', 1, $
        'display_type', 'spec', $
        'unit', unit, $
        'ytitle', 'Freq (Hz)', $
        'yrange', yrange, $
        'ylog', 1, $
        'ytickv', ytickv, $
        'ytickname', ytickname, $
        'yminor', yminor, $
        'zlog', 1, $
        'zrange', zrange, $
        'short_name', 'E' )
;    spec_var_combo = var+'_combo'
;    store_data, spec_var_combo, data=[spec_var,fc_vars]
    return, out_var

end


time_range = time_double(['2015-03-17','2015-03-18'])

foreach probe, ['a','b'] do begin
    prefix = 'rbsp'+probe+'_'
    
    spec_var = rbsp_read_efield_spec(time_range, probe=probe, update=update)
    
    fc_vars = list()
    foreach species, ['e','o','he','p'] do fc_vars.add, rbsp_read_gyro_freq(time_range, probe=probe, species=species)
    var = prefix+'fce_half'
    fce = get_var_data(prefix+'fce', times=times)
    store_data, var, times, fce*0.5
    fc_vars.add, var
    var = prefix+'flh'
    fcp = get_var_data(prefix+'fcp', times=times)
    store_data, var, times, fcp*43
    fc_vars.add, var
    fc_vars = fc_vars.toarray()
    fc_colors = get_color(n_elements(fc_vars))
    foreach var, fc_vars, ii do options, var, 'colors', fc_colors[ii]
    
    spec_combo_var = spec_var+'_combo'
    store_data, spec_combo_var, data=[spec_var,fc_vars]
    options, spec_combo_var, 'yrange', get_setting(spec_var,'yrange')
    options, spec_combo_var, 'labels', ''
endforeach




end