;+
; Read RBSP ion temperature in eV.
;-
pro rbsp_read_ion_temp, time, probe=probe, errmsg=errmsg

    pre0 = 'rbsp'+probe+'_'
    errmsg = ''

    ; read 'rbspx_ion_t'.
    rbsp_read_hope, time, id='l3%ion_t', probe=probe, errmsg=errmsg

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
        short_name: 'T!Dion', $
        ylog: 1}

end

time = time_double(['2013-05-01','2013-05-02'])
probe = 'b'
rbsp_read_ion_temp, time, probe=probe
end
