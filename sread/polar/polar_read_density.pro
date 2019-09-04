;+
; Read Polar density.
;-

pro polar_read_density, time, probe=probe, errmsg=errmsg

    polar_read_cdaweb_hydra, time, id='ele_density', errmsg=errmsg
    if errmsg ne '' then return

    var = 'po_ele_n'
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

time = time_double(['1999-09-25','1999-09-26'])
polar_read_density, time
end
