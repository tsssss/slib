;+
; Read RBSP MLT. Save as 'rbspx_mlt'
;-

function rbsp_read_mlt, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name

    prefix = 'rbsp'+probe+'_'
    var = prefix+'mlt'
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    files = rbsp_load_spice(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, var

    var_list = list()
    var_list.add, dictionary($
        'in_vars', var, $
        'out_vars', var, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, var

    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'MLT', $
        'unit', 'h' )
    return, var

end