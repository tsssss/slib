;+
; Read RBSP electron temperature in eV.
;-
pro rbsp_read_ele_temp, time, probe=probe, errmsg=errmsg

    pre0 = 'rbsp'+probe+'_'
    errmsg = ''

    ; read 'rbspx_ion_t'.
    rbsp_read_hope, time, id='l3%ele_t', probe=probe, errmsg=errmsg

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

time = time_double(['2013-06-07','2013-06-08'])
probe = 'b'
rbsp_read_ele_temp, time, probe=probe
end
