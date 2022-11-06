;+
; Read HOPE density.
;-

pro rbsp_read_density, time, probe=probe, data_type=data_type, errmsg=errmsg

    pre0 = 'rbsp'+probe+'_'
    if n_elements(data_type) eq 0 then data_type = 'l3%ele_n'

    ; read 'rbspx_ele_n'
    rbsp_read_hope, time, id=data_type, probe=probe, errmsg=errmsg
    if errmsg ne '' then return

    var = pre0+'ele_n'
    get_data, var, times, data
    index = where(data le -1e30, count)
    if count ne 0 then begin
        data[index] = !values.d_nan
        store_data, var, times, data
    endif
    add_setting, var, /smart, {$
        display_type: 'scalar', $
        unit: 'cm!U-3!N', $
        short_name: 'n!Dele', $
        ylog: 1}

end

time = time_double(['2013-06-07','2013-06-08'])
probe = 'a'
rbsp_read_density, time, probe=probe
end