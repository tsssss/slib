;+
; Read B field
;-

pro polar_read_bfield, time, probe=probe, errmsg=errmsg

    pre0 = 'po_'
    rgb = sgcolor(['red','green','blue'])

    polar_read_mfe, time, id='k0%bgsm', probe=probe, errmsg=errmsg

    bvar = pre0+'b_gsm'
    get_data, bvar, times, data
    fillval = !values.f_nan
    badval = -1e30
    index = where(data lt badval, count)
    if count ne 0 then begin
        data[index] = fillval
        store_data, bvar, times, data
    endif

    add_setting, bvar, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: rgb}

end

time = time_double(['1998-09-25','1998-09-26'])
polar_read_bfield, time
end