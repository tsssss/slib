;+
; Read OMNI polar cap index. Save as 'omni_pc_index'
;-

function omni_read_pc_index, input_time_range, errmsg=errmsg

    errmsg = ''
    retval = ''
    
    time_range = time_double(input_time_range)
    files = omni_load(time_range, errmsg=errmsg, id='cdaweb%hourly')
    if errmsg ne '' then return, retval

    prefix = 'omni_'
    var_list = list()
    
    pc_index_var = prefix+'pc_index'
    var_list.add, dictionary($
        'in_vars', 'PC_N_INDEX', $
        'out_vars', pc_index_var, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    add_setting, pc_index_var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'PC Index', $
        'unit', '#' )
    get_data, pc_index_var, times, data
    data = float(data)
    fillval = 999.9
    index = where(data ge fillval, count)
    if count ne 0 then begin
        data[index] = !values.f_nan
    endif
    store_data, pc_index_var, times, data
    return, pc_index_var

end

time_range = ['2013','2014']
var = omni_read_pc_index(time_range)
end