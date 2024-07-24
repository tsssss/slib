

function save_var_to_file_per_var, var, file=data_file, time_var=time_var, errmsg=errmsg, _extra=ex

    errmsg = ''

    ; Save data.
    data = get_var_data(var, vals, times=times, settings=settings)
    cdf_save_var, var, filename=data_file, value=data, _extra=ex, errmsg=errmsg
    if errmsg ne '' then return, 0
    if n_elements(settings) eq 0 then settings = dictionary()

    ; Save time.
    if n_elements(time_var) eq 0 then time_var = var+'_time'
    settings['DEPEND_0'] = time_var
    if ~cdf_has_var(time_var, filename=data_file) then begin
        cdf_save_var, time_var, filename=data_file, value=times
        cdf_save_setting, filename=data_file, varname=time_var, dictionary($
            'var_type', 'support_data', $
            'unit', 'sec', $
            'time_var_type', 'unix' )
    endif

    ; Save value.
    if n_elements(vals) ne 0 then begin
        value_var = var+'_value'
        settings['DEPEND_1'] = value_var
        if ~cdf_has_var(value_var, filename=data_file) then begin
            cdf_save_var, value_var, filename=data_file, value=vals
            cdf_save_setting, filename=data_file, varname=value_var, dictionary($
                'var_type', 'support_data' )
        endif
    endif

    cdf_save_setting, settings, filename=data_file, varname=var

    if errmsg ne '' then return, 0 else return, 1



end

function save_var_to_file, var_info, file=data_file, errmsg=errmsg, time_var=time_var, _extra=ex

    errmsg = ''

    if n_elements(data_file) eq 0 then begin
        errmsg = 'No input file ...'
        return, 0
    endif

    if file_test(data_file) eq 0 then cdf_touch, data_file

    var_type = size(var_info, type=1)
    ;print, var_info
    ;print, var_type

    if var_type eq 7 then begin
        ; string or strarr.
        foreach var, var_info do begin
            tmp = save_var_to_file_per_var(var, file=data_file, time_var=time_var, errmsg=errmsg, _extra=ex)
        endforeach
    endif else if var_type eq 11 then begin
        ; list or dict.
        foreach var, var_info do begin
            tmp = save_var_to_file_per_var(var, file=data_file, time_var=time_var, errmsg=errmsg, _extra=ex)
        endforeach
    endif else if var_type eq 8 then begin
        ; struct.
        foreach var, dictionary(var_info) do begin
            tmp = save_var_to_file_per_var(var, file=data_file, time_var=time_var, errmsg=errmsg, _extra=ex)
        endforeach
    endif
    
    if errmsg ne '' then return, 0 else return, 1


end