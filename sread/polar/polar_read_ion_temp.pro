;+
; Read Polar ion temperature.
;-
pro polar_read_ion_temp, time, probe=probe, errmsg=errmsg

    pre0 = 'po_'

    ; read 'thx_ion_t'
    polar_read_cdaweb_hydra, time, id='ion_temp_para', probe=probe, errmsg=errmsg
    if errmsg ne '' then return
    polar_read_cdaweb_hydra, time, id='ion_temp_perp', probe=probe, errmsg=errmsg
    if errmsg ne '' then return

    vars = pre0+'ion_t_'+['para','perp']
    foreach var, vars do begin
        get_data, var, times, data
        index = where(data le -1e30, count)
        if count ne 0 then begin
            data[index] = !values.d_nan
            store_data, var, times, data
        endif
    endforeach

    weights = [1.,2]/3  ; [T_perp,T_perp,T_para]
    get_data, vars[0], times
    ntime = n_elements(times)
    data = fltarr(ntime)
    foreach var, vars, ii do data += weights[ii]*get_var_data(var)
    var = pre0+'ion_t'
    store_data, var, times, data
    add_setting, var, /smart, {$
        display_type: 'scalar', $
        unit: 'eV', $
        short_name: 'T!Dion', $
        ylog: 1}

end

time = time_double(['1996-01-01','1996-01-01'])
probe = 'a'
polar_read_ion_temp, time, probe=probe
polar_read_ele_temp, time, probe=probe
end
