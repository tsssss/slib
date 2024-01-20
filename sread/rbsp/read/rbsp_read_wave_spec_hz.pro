;+
; Read E and B wave spectrogram.
;
; Return rbspx_[e,b]_spec_hz.
;-

function rbsp_read_wave_spec_hz, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, id=id, update=update, suffix=suffix

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(id) eq 0 then id = 'b'

    if n_elements(suffix) eq 0 then suffix = '_hz'
    out_var = prefix+id+'_spec'+suffix
    if keyword_set(get_name) then return, out_var
    time_range = time_double(input_time_range)
    if keyword_set(update) then del_data, out_var
    if ~check_if_update(out_var, time_range) then return, out_var

    if id eq 'e' then begin
        field_var = rbsp_read_efield(time_range, probe=probe, resolution='survey', errmsg=errmsg)
    endif else begin
        field_var = rbsp_read_bfield(time_range, probe=probe, resolution='hires', errmsg=errmsg)
        r_var = rbsp_read_orbit(time_range, probe=probe)
        bmod_var = geopack_read_bfield(time_range, probe=probe, $
            r_var=r_var, model='t89', igrf=1, t89_par=2)
        b_gsm = get_var_data(field_var, times=times, limits=lim)
        bmod_gsm = get_var_data(bmod_var, at=times)
        db_gsm = b_gsm-bmod_gsm
        db_var = prefix+'db_gsm'
        store_data, db_var, times, db_gsm, limits=lim
        field_var = db_var
    endelse
    if errmsg ne '' then return, retval

    
    time_step = 1d/32
    common_times = make_bins(time_range, time_step)
    interp_time, field_var, common_times
    scale_info = {s0:time_step*2, s1:16, dj:1d/8, ns:0d }
    spec_var = stplot_mor_new(field_var, scale_info=scale_info)
    data = get_var_data(spec_var, freqs, times=times, limits=lim)
    
    freq_range = [0.1,10]
    freq_index = where_pro(freqs, '[]', freq_range, count=nfreq)
    if nfreq eq 0 then begin
        errmsg = 'Invalid frequencies ...'
        return, retval
    endif
    ; Conver to psd spectrogram in X^2/Hz.
    data = data[*,freq_index]
    freqs = freqs[freq_index]
    cwt_info = get_setting(spec_var, 'cwt_info')
    c_unit = 2*cwt_info.c_tau*cwt_info.dt/cwt_info.cdelta
    data *= c_unit  ; convert unit from (X)^2 to (X)^2/Hz
    store_data, out_var, times, data, freqs
    
    ; e 1e-9, 1e-1
    unit = (id eq 'b')? 'nT!U2!N/Hz': '(mV/m)!U2!N/Hz'
    zrange = (id eq 'b')? [1e-3,1e1]: [1e-3,1e1]
    add_setting, out_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'no_interp', 1, $
        'display_type', 'spec', $  
        'unit', unit, $
        'ytitle', 'Freq (Hz)', $
        'yrange', freq_range, $
        'ylog', 1, $
        'zlog', 1, $
        'zrange', zrange, $
        'short_name', strupcase(id) )
    return, out_var

end

time_range = time_double(['2015-03-17','2015-03-18'])
e_zrange = [1e-8,1e1]
foreach probe, ['a','b'] do begin
    prefix = 'rbsp'+probe+'_'
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
    foreach id, ['e'] do var = rbsp_read_wave_spec_hz(time_range, probe=probe, id=id, update=0)
    foreach id, ['b'] do var = rbsp_read_wave_spec_hz(time_range, probe=probe, id=id, update=0)
    foreach id, ['e','b'] do var = rbsp_read_wave_spec_khz(time_range, probe=probe, id=id, update=0)
    foreach id, ['e'] do var = rbsp_read_wave_spec_mhz(time_range, probe=probe, update=0)
    vars = prefix+'e_spec_'+['mhz','khz','hz']
    foreach var, vars do begin
        tvar = var+'_combo'
        store_data, tvar, data=[var,fc_vars]
        options, tvar, 'yrange', get_setting(var,'yrange')
        options, tvar, 'labels', ''
    endforeach
    e_vars = vars+'_combo'
endforeach

end