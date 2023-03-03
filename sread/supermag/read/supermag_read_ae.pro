;+
; Read SME (AE-like) 1D.
;-

function supermag_read_ae, input_time_range, errmsg=errmsg, get_name=get_name

    compile_opt idl2
    supermag_api

    time_range = time_double(input_time_range)
    files = supermag_load_indices_array(time_range, errmsg=errmsg)
    if errmsg ne '' then return, ''

    prefix = 'sm_'
    sme_var = prefix+'ae'
    if keyword_set(get_name) then return, sme_var

    in_vars = ['sme']
    time_var = 'time'
    vatt_info = dictionary($
        'sme', dictionary($
            'VAR_TYPE', 'data', $
            'DEPEND_0', time_var, $
            'UNITS', 'nT', $
            'VAR_NOTES', 'SME index' ) )


    secofday = constant('secofday')
    foreach file, files do begin
        foreach var, in_vars do begin
            if cdf_has_var(var, filename=file) then continue
            common_times = cdf_read_var(time_var, filename=file)
            day_time_range = common_times[0]+[0,secofday]
            ntime = n_elements(common_times)
            if var eq 'sme' then begin
                tmp = supermaggetindicesarray(day_time_range, times, sme=val)
                if ntime ne n_elements(times) then message, 'Inconsistency ...'
                cdf_save_var, var, value=val, filename=file
                cdf_save_setting, vatt_info[var], varname=var, filename=file
            endif
        endforeach
    endforeach


    var_list = list()
    out_vars = prefix+in_vars
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg


;---Further processing.
    sme_var = rename_var(prefix+'sme', output=sme_var)
    get_data, sme_var, times, sme
    add_setting, sme_var, smart=1, dictionary($
        'display_type', 'scalar', $
        'unit', 'nT', $
        'short_name', 'AE' )
    
    return, sme_var


end


time_range = ['2019-01-01','2019-01-02']
var = supermag_read_ae(time_range)
end