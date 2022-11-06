;+
; Read OMNI F10.7. Save as 'omni_f10.7'
;-

function omni_read_f107, input_time_range, errmsg=errmsg

    errmsg = ''
    retval = ''
    
    time_range = time_double(input_time_range)
    files = omni_load(time_range, errmsg=errmsg, id='cdaweb%hourly')
    if errmsg ne '' then return, retval

    prefix = 'omni_'
    var_list = list()
    
    f107_var = prefix+'f107'
    var_list.add, dictionary($
        'in_vars', 'F10_INDEX', $
        'out_vars', f107_var, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    add_setting, f107_var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'F10.7', $
        'unit', '10!U-22!N J/s-m!U2!N-Hz' )
    get_data, f107_var, times, data
    data = float(data)
    fillval = 999.9
    index = where(data ge fillval, count)
    if count ne 0 then begin
        data[index] = !values.f_nan
    endif
    store_data, f107_var, times, data
    return, f107_var

end

time_range = ['2013','2014']
var = omni_read_f107(time_range)
end