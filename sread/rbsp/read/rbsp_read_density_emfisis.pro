function rbsp_read_density_emfisis, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    var = prefix+'density_emfisis'
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    files = rbsp_load_emfisis(time_range, probe=probe, id='l4%density', errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()
    var_list.add, dictionary($
        'in_vars', ['density'], $
        'out_vars', [var], $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000')
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsgm
    if errmsg ne '' then return, retval
    
    add_setting, var, /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'cm!U-3!N', $
        'ylog', 1, $
        'short_name', 'Density' )
    time_step = 6
    uniform_time, var, time_step
    return, var
    
end

time_range = time_double(['2015-02-17/22:00','2015-02-18/08:00'])
time_range = time_double(['2013-05-01','2013-05-02'])
probe = 'b'
var = rbsp_read_density_emfisis(time_range, probe=probe)
end