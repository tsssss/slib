;+
; Read Themis MLT.
;-

function themis_read_mlt, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name

    prefix = 'th'+probe+'_'
    errmsg = ''
    var = prefix+'mlt'
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    files = themis_load_ssc(time_range, probe=probe, id='l2')

;---Read data.
    var_list = list()
    in_vars = 'SM_LCT_T'
    out_vars = prefix+'mlt'
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''
    
    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'unit', 'h', $
        'short_name', 'MLT' )

    return, var

end


time_range = ['2008-01-19','2008-01-20']
probe = 'a'
var = themis_read_mlt(time_range, probe=probe)
end