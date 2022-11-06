;+
; Read ion velocity in GSM in km.
;-

pro polar_read_ion_vel, time, probe=probe, errmsg=errmsg

    polar_read_cdaweb_hydra, time, id='ion_vel', errmsg=errmsg
    if errmsg ne '' then return

    var = 'po_u_gsm'
    get_data, var, times, data
    index = where(data le -1e30, count)
    if count ne 0 then data[index] = !values.d_nan
    if count ne 0 then begin
        data[index] = !values.d_nan
        store_data, var, times, data
    endif
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'km/s', $
        short_name: 'U!S!Uion!N!R', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: sgcolor(['red','green','blue'])}

end

time = time_double(['1998-09-25','1998-09-26'])
time = time_double(['1996-05-28','1996-05-31'])
polar_read_ion_vel, time
end