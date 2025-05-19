;+
; RBSP-A perigee efield sometimes is very large.
;-


    time_range = time_double('2018'+['-06-01','-12-31'])   ; -A.
    time_range = time_double('2019'+['-01-01','-10-31'])   ; -A.
    time_range = time_double(['2016-07-01','2017-02-01'])   ; -A.
    time_range = time_double(['2015-01-01','2019-01-01'])   ; -A.


    probe = 'a'
    boom_pair = '24'
    in_vars = [['efield_in_corotation_frame_spinfit_mgse','flags_charging_bias_eclipse']+'_'+boom_pair]
    prefix = 'rbsp'+probe+'_'
    out_vars = prefix+['e_mgse','flags']
    boom_index = fix([strmid(boom_pair,0,1),strmid(boom_pair,1,1)])
    

    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'rbsp'])
    if n_elements(version) eq 0 then version = 'v02'

    valid_range = (probe eq 'a')? time_double(['2012-09-08','2019-10-15']): time_double(['2012-09-08','2019-07-17'])
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_efw-l4_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,rbspx,'level4','%Y']

    request = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', in_vars, $
                'out_vars', out_vars, $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch16')) )
    files = prepare_files(request=request, time=time_range)
    ;cdf2tplot, files
    
    
    bps = ['12','34','13','14','23','24']
    vars = 'efield_in_inertial_frame_spinfit_mgse_'+bps
    re = constant('re')
    dis = snorm(get_var_data('position_gse'))/re
    perigee_lshell = 3
    perigee_index = where(dis ge perigee_lshell, count)
    fillval = !values.f_nan
    foreach var, vars, var_id do begin
        get_data, var, times, data
        data[perigee_index,*] = fillval
        store_data, var, times, data, limits={$
            ytitle:'Spinfit from V'+bps[var_id]+'!C(mV/m)', $
            colors: constant('rgb'), $
            labels: constant('xyz'), $
            labflag: -1, $
            yrange: [-1,1]*100, $
            ystyle: 1, $
            constant: [0,[-1,1]*50] }
    endforeach
    
    ; MLT.
    get_data, 'mlt', times, data
    data[perigee_index] = fillval
    store_data, 'mlt', times, data, limits={$
        ytitle: '(hr)', $
        labels: 'MLT', $
        labflag: -1, $
        yrange: [0,24], $
        ystyle: 1 }
        
    
    ; eclipse flag.
    get_data, 'flags_all_12', times, data
    store_data, 'eclipse', times, data[*,1], limits={$
        ytitle: 'Flag (#)', $
        yrange: [-0.1,1.1], $
        ystyle: 1, $
        ytickv: [0,1], $
        yticks: 1, $
        yminor: 0, $
        labels: 'Eclipse' }
    

    timespan, time_range[0], total(time_range*[-1,1]), /seconds
    tmp = rbsp_load_maneuver_times(probe)
    times = [tmp.estart,tmp.eend]
    
    tplot, [vars,'mlt','eclipse'], trange=time_range
    timebar, times, color=sgcolor('red')
    

end
