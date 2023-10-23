;+
; Read omni index.
;-

function omni_read_symh, input_time_range, errmsg=errmsg, get_name=get_name, coord=coord, _extra=ex

    errmsg = ''
    retval = ''


    prefix = 'omni_'
    var = prefix+'dst'
    if keyword_set(get_name) then return, var
    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var

    if n_elements(resolution) eq 0 then resolution = '1min'
    files = omni_load(time_range, errmsg=errmsg, id='cdaweb%hro%'+resolution)
    if errmsg ne '' then return, retval

    var_list = list()
    var_list.add, dictionary($
        'in_vars', ['SYM_H'], $
        'out_vars', prefix+['dst'], $
        'time_var_type', 'epoch', $
        'time_var_name', 'Epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    
    ; Remove fillval.
    get_data, var, times, data
    index = where(abs(data) ge 9999, count)
    if count ne 0 then begin
        data[index] = !values.f_nan
        store_data, var, times, data
    endif

    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'nT', $
        'short_name', 'SymH' )
    return, var


end


time_range = ['2019-01-01','2019-01-02']
var = omni_read_symh(time_range)
end