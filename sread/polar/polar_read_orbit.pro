;+
; Read Polar position in GSM. Save as 'po_r_gsm'
;
; time. A time or a time range in ut sec.
;-
;

pro polar_read_orbit, time, errmsg=errmsg, coordinate=coord, probe=probe

    if n_elements(coord) eq 0 then coord = 'gsm'
    ;var = strupcase(coord+'_pos')

    ; read orbit data.
    polar_read_ssc, time, id='or', errmsg=errmsg;, in_vars=var
    if errmsg ne '' then return

    pre0 = 'po_'
    rgb = sgcolor(['red','green','blue'])
    re1 = 1d/6378d

    var = pre0+'r_gsm'
    rgse_var = 'po_pos_gse'
    get_data, rgse_var, times, rgse
    rgsm = cotran(rgse, times, 'gse2gsm')*re1
    store_data, var, times, rgsm
    settings = { $
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: rgb}
    add_setting, var, settings, /smart
    del_data, rgse_var

    var = pre0+'mlat'
    settings = { $
        display_type: 'scalar', $
        unit: 'deg', $
        short_name: 'MLat'}
    add_setting, var, settings, /smart


    var = pre0+'mlt'
    settings = { $
        display_type: 'scalar', $
        unit: 'hr', $
        short_name: 'MLT'}
    add_setting, var, settings, /smart


    var = pre0+'ilat'
    settings = { $
        display_type: 'scalar', $
        unit: 'deg', $
        short_name: 'ILat'}
    add_setting, var, settings, /smart


end

time = time_double(['1996-12-25','1996-12-26'])
time = time_double(['1999-12-25','1999-12-26'])
time = time_double(['1996-02-27','1996-03-03'])
polar_read_orbit, time
end
