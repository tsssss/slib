;+
; Check long-term data quality of the L4 data.
;-

;---Settings.
    ;time_range = time_double('2012'+['-10-01','-12-31/24:00'])
    time_range = time_double('2015'+['-01-01','-12-31/24:00'])
    ;time_range = time_double('2015'+['-03-13','-03-16'])   ; -A.
    ;time_range = time_double('2015'+['-09-01','-10-31/24:00'])

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
    read_files, time_range, files=files, request=request
    
    
    e_var = out_vars[0]
    flag_var = out_vars[1]
    options, e_var, 'colors', constant('rgb')
    options, flag_var, 'yrange', [-1,1]*0.1+[0,1]
    
    ; Load boom flags.
    rbsp_efw_read_boom_flag, time_range, probe=probe
    boom_flag_var = prefix+'boom_flag'
    interp_time, boom_flag_var, to=e_var
    boom_flag = get_var_data(boom_flag_var)

    flags = get_var_data(flag_var)

    
    ; apply flags.
    fillval = !values.f_nan
    index = where(total(flags,2) ne 0, count)
    e_mgse = get_var_data(e_var, times=times)
    e_mgse[index,*] = fillval
    store_data, e_var+'_flag1', times, e_mgse
    
    index = where(total(boom_flag[*,boom_index],2) eq 0, count)
    e_mgse = get_var_data(e_var, times=times)
    e_mgse[index,*] = fillval
    store_data, e_var+'_flag2', times, e_mgse
    

    
    index = where(total(flags,2) ne 0 or total(boom_flag[*,boom_index],2) eq 0, count)
    pad_time = 600. ; sec.
    if count ne 0 then begin
        e_mgse = get_var_data(e_var, times=times)
        bad_times = times[time_to_range(index,time_step=1)]
        nbad_time = n_elements(bad_times)*0.5
        for ii=0,nbad_time-1 do begin
            index = where_pro(times, '[]', bad_times[ii,*]+[-1,1]*pad_time, count=count)
            if count eq 0 then continue
            e_mgse[index,*] = fillval
        endfor
        store_data, e_var+'_flag', times, e_mgse
    endif
    
    tplot, e_var+['','_flag'], trange=time_range

end
