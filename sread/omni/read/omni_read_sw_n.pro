;+
; Read omni solar wind parameters.
;-

function omni_read_sw_n, input_time_range, errmsg=errmsg, get_name=get_name, _extra=ex

    errmsg = ''
    retval = ''

    time_range = time_double(input_time_range)
    if n_elements(resolution) eq 0 then resolution = '1min'
    files = omni_load(time_range, errmsg=errmsg, id='cdaweb%hro%'+resolution)
    if errmsg ne '' then return, retval


    prefix = 'omni_'
    var = prefix+'sw_n'
    if keyword_set(get_name) then return, var

    in_var = 'proton_density'
    var_list = list()
    var_list.add, dictionary($
        'in_vars', [in_var], $
        'out_vars', [var], $
        'time_var_type', 'epoch', $
        'time_var_name', 'Epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    ; Remove fillval.
    get_data, var, times, data
    vatts = cdf_read_setting(in_var, filename=files[0])
    fillval = vatts['FILLVAL']
    index = where(data ge fillval, count)
    if count ne 0 then begin
        data[index] = !values.f_nan
        store_data, var, times, data
    endif

    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'unit', 'cm!U-3', $
        'short_name', 'SW N' )
    return, var

end


time_range = ['2019-01-01','2019-01-02']
var = omni_read_sw_n(time_range)
end