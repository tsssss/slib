;+
; Read RBSP Lshell. Save as 'rbspx_lshell'
;-

function rbsp_read_lshell, input_time_range, probe=probe, errmsg=errmsg

    time_range = time_double(input_time_range)
    files = rbsp_load_spice(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return

    prefix = 'rbsp'+probe+'_'
    var_list = list()

    lshell_var = prefix+'lshell'
    var_list.add, dictionary($
        'in_vars', lshell_var, $
        'out_vars', lshell_var, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return

    add_setting, lshell_var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'L', $
        'unit', '#' )
    return, lshell_var

end