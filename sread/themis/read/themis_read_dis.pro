;+
; Read Themis dis.
;-

function themis_read_dis, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name

    prefix = 'th'+probe+'_'
    errmsg = ''
    var = prefix+'dis'
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    files = themis_load_ssc(time_range, probe=probe, id='l2')

;---Read data.
    var_list = list()
    in_vars = 'XYZ_GSM'
    out_vars = prefix+'r_gsm'
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''

    r_var = prefix+'r_gsm'
    get_data, r_var, times, vec_gsm
    store_data, var, times, snorm(vec_gsm)
    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'unit', 'Re', $
        'short_name', '|R|' )

    return, var

end

time_range = ['2008-01-19','2008-01-20']
probe = 'a'
var = themis_read_dis(time_range, probe=probe)
end