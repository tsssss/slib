;+
;-
pro polar_read_ele_temp, time, probe=probe, errmsg=errmsg

    pre0 = 'po_'

    ; read 'thx_ion_t'
    polar_read_cdaweb_hydra, time, id='ele_temp', probe=probe, errmsg=errmsg
    if errmsg ne '' then return

    var = pre0+'ele_t'
    get_data, var, times, data
    index = where(data le -1e30, count)
    if count ne 0 then begin
        data[index] = !values.d_nan
        store_data, var, times, data
    endif
    add_setting, var, /smart, {$
        display_type: 'scalar', $
        unit: 'eV', $
        short_name: 'T!Dele', $
        ylog: 1}

end

time = time_double(['2004-08-28','2004-08-29'])
probe = 'a'
polar_read_ele_temp, time, probe=probe
end
