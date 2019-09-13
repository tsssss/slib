;+
; Read Themis ESA density. Default is to ready 3 samples/sec.
;-

pro themis_read_density, time, probe=probe, resolution=resolution, errmsg=errmsg

    pre0 = 'th'+probe+'_'
    resolution = (keyword_set(keyword))? strlowcase(resolution): '3sec'
    case resolution of
        '3sec': begin
            dt = 3
            data_type = 'l2%ele_n'
        end
    endcase

    ; read 'thx_ele_n'
    themis_read_esa, time, id=data_type, probe=probe, errmsg=errmsg
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
themis_read_density, time, probe=probe
end