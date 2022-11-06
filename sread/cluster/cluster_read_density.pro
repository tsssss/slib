
pro cluster_read_density, time, probe=probe, errmsg=errmsg

    pre0 = 'c'+probe+'_'

    ; read 'cx_ele_n'
    cluster_read_peace, time, id='ele_n', probe=probe, errmsg=errmsg
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

time = time_double(['2014-08-28','2014-08-29'])
probe = 'a'
cluster_read_density, time, probe=probe
end
