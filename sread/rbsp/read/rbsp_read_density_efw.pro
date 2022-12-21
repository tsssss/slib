function rbsp_read_density_efw, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    var = prefix+'density_efw'
    if keyword_set(get_name) then return, var

;    time_range = time_double(input_time_range)
;    files = rbsp_load_efw(time_range, probe=probe, id='l3%efw', errmsg=errmsg)
;    if errmsg ne '' then return, retval
;
;    var_list = list()
;    var_list.add, dictionary($
;        'in_vars', ['density'], $
;        'out_vars', [var], $
;        'time_var_name', 'epoch', $
;        'time_var_type', 'epoch16')
;    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsgm
;    if errmsg ne '' then return, retval
    
    time_range = time_double(input_time_range)
    if n_elements(boom_pair) eq 0 then boom_pair = '12'
    rbsp_efw_phasef_read_density, time_range, probe=probe, boom_pair=boom_pair, dmin=1e-2
    suffix = '_'+boom_pair
    orig_var = prefix+'density'+suffix
    var = rename_var(orig_var, output=var)
    
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
var = rbsp_read_density_efw(time_range, probe=probe)
end