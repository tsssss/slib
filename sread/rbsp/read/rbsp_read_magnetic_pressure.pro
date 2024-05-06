

function rbsp_read_magnetic_pressure, b_var=b_var, $
    errmsg=errmsg, get_name=get_name, update=update, suffix=suffix

    prefix = get_prefix(b_var)
    if n_elements(suffix) eq 0 then suffix = ''
    var_info = prefix+'p_mag'+suffix
    if keyword_set(get_name) then return, var_info

    if keyword_set(update) then del_data, var_info
    if ~check_if_update(var, time_range) then return, var_info

    bmag = snorm(get_var_data(b_var, times=times))
    mu0 = 4*!dpi*1e-7
    pmag = (bmag*1e-9)^2/(2*mu0)*1e9
    store_data, var_info, times, pmag
    add_setting, var_info, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'P!Dmag!N', $
        'unit', 'nPa' )
    return, var_info

end