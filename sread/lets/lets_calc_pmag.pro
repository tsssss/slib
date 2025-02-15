;+
;-

function lets_calc_pmag, b_var=b_var, $
    var_info=var_info, $
    update=update, get_name=get_name, suffix=suffix, errmsg=errmsg, $
    save_to=data_file, time_var=time_var

    if n_elements(var_info) eq 0 then begin
        var_info = strlowcase(get_prefix(b_var)+'pmag')
    endif
    time_range = get_var_setting(b_var, 'requested_time_range')

    ; Check if update in memory.
    if keyword_set(update) then tmp = delete_var_from_memory(var_info)
    if ~check_if_update_memory(var_info, time_range) then return, var_info

    ; Check if loading from file.
    if keyword_set(update) then tmp = delete_var_from_file(var_info, file=data_file, errmsg=errmsg)
    is_success = read_var_from_file(var_info, file=data_file, errmsg=errmsg)
    if is_success then return, var_info

    b_vec = get_var_data(b_var, times=times, settings=settings)
    pmag = calc_magnetic_pressure(b_vec)
    store_data, var_info, times, pmag
    add_setting, var_info, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'P!DB', $
        'unit', 'nPa' )
    foreach key, ['requested_time_range','probe','mission'] do begin
        if settings.haskey(key) then options, var_info, key, settings[key]
    endforeach

    ; Save to file.
    if n_elements(data_file) ne 0 then begin
        is_success = save_var_to_file(var_info, file=data_file, time_var=time_var)
    endif

    return, var_info

end