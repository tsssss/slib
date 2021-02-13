;+
; Compare B field with and without eclipse correction.
;-

;---Settings.
    time_range = time_double(['2014-08-28','2014-08-29'])
    probes = ['a','d','e']
    probes = ['a']


;---Load data.
    foreach probe, probes do begin
        prefix = 'th'+probe+'_'
        
        ; Load 4 Hz data.
        thm_load_fgm, probe=probe, level=1, type='calibrated', suffix='_before', use_eclipse_corrections=0, trange=time_range
        thm_load_fgm, probe=probe, level=1, type='calibrated', suffix='_after', use_eclipse_corrections=1, trange=time_range
        vars = prefix+'fgl_'+['after','before']
        foreach var, vars do begin
            dsl2gse, var, prefix+'state_spinras', prefix+'state_spindec', var+'_gse'
        endforeach
        
        ; Load 3 sec data.
        themis_read_fgm, time_range, id='l2%fgs', probe=probe, errmsg=errmsg, _extra=ex
        cotrans, prefix+'fgs_gsm', prefix+'fgs_gse', /gsm2gse
        
        ; Get dis.
        dis = snorm(get_var_data(prefix+'state_pos_gse', times=times))
        store_data, prefix+'dis', times, dis/constant('re')
        options, prefix+'dis', 'constant', 1
        
        vars = prefix+['fgs_gse','fgl_before_gse','fgl_after_gse']
        options, vars, 'colors', constant('rgb')
        options, vars, 'labels', constant('xyz')
        
        tplot, [vars,prefix+'dis']
        dis = get_var_data(prefix+'dis', times=times)
        index = where(dis le 4, count)
        timebar, times[index[[0,count-1]]]
        index = where(dis ge 11.5, count)
        timebar, times[index[[0,count-1]]]
        stop
    endforeach

end