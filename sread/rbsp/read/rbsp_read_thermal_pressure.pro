;+
; Read RBSP thermal pressure.
;-

function rbsp_read_thermal_pressure, input_time_range, probe=probe, dens_var=dens_var, $
    get_name=get_name, update=update, suffix=suffix, errmsg=errmsg, extra=ex

    errmsg = ''
    retval = !null
    
    prefix = 'rbsp'+probe+'_'
    if n_elements(suffix) eq 0 then suffix = ''
    var_info = prefix+'p_thermal'+suffix
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

    if n_elements(dens_var) eq 0 then begin
        dens_var = rbsp_read_density(time_range, probe=probe, _extra=ex, errmsg=errmsg)
        if errmsg ne '' then return, retval
    endif
    density = get_var_data(dens_var, times=times)
    
    temp_var = rbsp_read_temperature(time_range, probe=probe, species=species, errmsg=errmsg)
    if errmsg ne '' then return, retval
    temp = get_var_data(temp_var, at=times)
    pthermal = calc_thermal_pressure(density, temp)
    
    foreach species, ['p','o'] do begin
        the_density_var = rbsp_read_density_hope(time_range, probe=probe, species=species, errmsg=errmsg)
        if errmsg ne '' then return, retval
        the_temp_var = rbsp_read_temperature(time_range, probe=probe, species=species, errmsg=errmsg)
        if errmsg ne '' then return, retval
        pthermal += calc_thermal_pressure($
            get_var_data(the_density_var, at=times), $
            get_var_data(the_temp_var, at=times))
    endforeach

    store_data, var_info, times, pthermal
    add_setting, var_info, smart=1, dictionary($
        'unit', 'nPa', $
        'short_name', 'P!Dth!N', $
        'display_type', 'scalar' )
    return, var_info

end