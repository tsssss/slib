;+
; Read Themis Lshell.
;-

function themis_read_lshell, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name

    prefix = 'th'+probe+'_'
    errmsg = ''
    var = prefix+'lshell'
    if keyword_set(get_name) then return, var
    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var
    files = themis_load_ssc(time_range, probe=probe, id='l2')


;---Read data.
    var_list = list()
    in_vars = 'L_VALUE'
    out_vars = prefix+'lshell'
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''
    
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', '#', $
        'short_name', 'L' )

    return, var

end


time_range = ['2008-01-19','2008-01-20']
probe = 'a'
var = themis_read_lshell(time_range, probe=probe)
end