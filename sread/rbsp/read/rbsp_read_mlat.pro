;+
; Read RBSP MLat. Save as 'rbspx_mlat'
;-

function rbsp_read_mlat, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name, update=update

    errmsg = ''
    
    prefix = 'rbsp'+probe+'_'
    var = prefix+'mlat'
    if keyword_set(get_name) then return, var
    if keyword_set(update) then del_data, var
    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var

    r_var = rbsp_read_orbit(time_range, probe=probe, coord='mag', get_name=1)
    if check_if_update(r_var, time_range) then begin
        r_var = rbsp_read_orbit(time_range, probe=probe, coord='mag', errmsg=errmsg)
        if errmsg ne '' then return, var
    endif
    
    r_mag = get_var_data(r_var, times=times)
    mlat = asin(r_mag[*,2]/snorm(r_mag))*constant('deg')
    store_data, var, times, mlat
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'short_name', 'MLat', $
        'unit', 'deg' )
    return, var
    
    
;    files = rbsp_load_spice(time_range, probe=probe, errmsg=errmsg)
;    if errmsg ne '' then return, var
;
;    var_list = list()
;    var_list.add, dictionary($
;        'in_vars', var, $
;        'out_vars', var, $
;        'time_var_name', 'Epoch', $
;        'time_var_type', 'epoch' )
;    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
;    if errmsg ne '' then return, var
;
;    add_setting, var, smart=1, dictionary($
;        'display_type', 'scalar', $
;        'short_name', 'MLat', $
;        'unit', 'deg' )
;    return, var

end