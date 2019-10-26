;+
; Read THEMIS electron temperature in eV.
;-
pro themis_read_ion_temp, time, probe=probe, errmsg=errmsg

    pre0 = 'th'+probe+'_'

    ; read 'thx_ion_t'
    data_type = 'l2%ion_t'
    themis_read_esa, time, id=data_type, probe=probe, errmsg=errmsg
    if errmsg ne '' then return

    var = pre0+'ion_t'
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

time = time_double(['2014-08-28','2014-08-29'])
probe = 'a'
themis_read_ion_temp, time, probe=probe
end
