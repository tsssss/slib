;+
; Read Symh (Dst-like) 1D.
;-

function supermag_read_symh, input_time_range, errmsg=errmsg, get_name=get_name

    compile_opt idl2
    supermag_api

    time_range = time_double(input_time_range)
    files = supermag_load_indices_array(time_range, errmsg=errmsg)
    if errmsg ne '' then return, ''

    prefix = 'sm_'
    var_info = prefix+'symh'
    if keyword_set(get_name) then return, var_info

    in_vars = ['smr']
    time_var = 'time'
    vatt_info = dictionary($
        'smr', dictionary($
            'VAR_TYPE', 'data', $
            'DEPEND_0', time_var, $
            'UNITS', 'nT', $
            'VAR_NOTES', 'SMR index' ) )


    secofday = constant('secofday')
    foreach file, files do begin
        foreach var, in_vars do begin
            if cdf_has_var(var, filename=file) then continue
            common_times = cdf_read_var(time_var, filename=file)
            day_time_range = common_times[0]+[0,secofday]
            ntime = n_elements(common_times)
            if var eq 'smr' then begin
                tmp = supermaggetindicesarray(day_time_range, times, smr=val)
                if ntime ne n_elements(times) then message, 'Inconsistency ...'
                cdf_save_var, var, value=val, filename=file
                cdf_save_setting, vatt_info[var], varname=var, filename=file
            endif
        endforeach
    endforeach


    var_list = list()
    out_vars = var_info
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg


;---Further processing.
    add_setting, var_info, smart=1, dictionary($
        'display_type', 'scalar', $
        'unit', 'nT', $
        'short_name', 'SMR' )
    
    return, var_info

end


tr = ['2015-03-17','2015-03-19']
var = supermag_read_symh(tr)
dst_var = omni_read_symh(tr)
end