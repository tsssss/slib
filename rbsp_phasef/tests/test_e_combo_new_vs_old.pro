;+
; Test the perigee residue of the spinfit E combo.
;-


    time_range = time_double(['2016-01-01','2018-01-01'])
    ;time_range = time_double(['2016-01-01','2016-01-02'])
    probe = 'a'
    versions = ['v01','v02']
    
    prefix = 'rbsp'+probe+'_'
    
    ; Load spinfit E combo.
    pairs = ['14','24','13','23']
    foreach version, versions do begin
        vars = prefix+'e_spinfit_mgse_v'+pairs
        if tnames(vars[0]+'_v01') ne '' then continue
        rbsp_efw_phasef_read_e_spinfit_diagonal, time_range, probe=probe, version=version
        foreach var, vars do tplot_rename, var, var+'_'+version
    endforeach
    
    ; Load spinfit E.
    pairs = ['12','34']
    vars = prefix+'e_spinfit_mgse_v'+pairs
    if tnames(vars[0]) eq '' then begin
        rbsp_efw_phasef_read_e_uvw_diagonal, time_range, probe=probe
    endif
    
    ; Load position.
    pos_var = prefix+'r_gse'
    if tnames(pos_var) eq '' then begin
        rbsp_read_orbit, time_range, probe=probe
    endif

    
    
    ; Settings.
    vars = prefix+'e_spinfit_mgse_v'+['12','24_'+versions]
    options, vars, 'yrange', [-1,1]*10
    
    perigee_lshell = 2.
    fillval = !values.f_nan
    foreach var, vars do begin
        get_data, var, times, data, limits=lim
        dis = snorm(get_var_data(pos_var, at=times))
        index = where(dis ge perigee_lshell)
        data[index,*] = fillval
        store_data, var+'_plot', times, data, limits=lim
    endforeach
    

end
