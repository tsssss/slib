;+
; Read Polar position in GSM. Save as 'po_r_gsm'
;
; time. A time or a time range in ut sec.
;-
;

pro polar_read_orbit, time, errmsg=errmsg, coordinate=coord

    if n_elements(coord) eq 0 then coord = 'gsm'
    var = strupcase(coord+'_pos')

    ; read orbit data.
    polar_read_ssc, time, id='or_def', errmsg=errmsg, in_vars=var
    if errmsg ne '' then polar_read_ssc, time, id='or_pre', errmsg=errmsg, in_vars=var
    if errmsg ne '' then return

    pre0 = 'po_'
    re1 = 1d/6378d


    var = pre0+'r_gsm'
    rename_var, 'GSM_POS', to=var
    sys_multiply, var, re1, to=var
    settings = { $
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: [6,4,2]}
    add_setting, var, settings, /smart


    var = pre0+'mlat'
    rename_var, 'MAG_LATITUDE', to=var
    settings = { $
        display_type: 'scalar', $
        unit: 'deg', $
        short_name: 'MLat'}
    add_setting, var, settings, /smart


    var = pre0+'mlt'
    rename_var, 'EDMLT_TIME', to=var
    settings = { $
        display_type: 'scalar', $
        unit: 'hr', $
        short_name: 'MLT'}
    add_setting, var, settings, /smart


    var = pre0+'ilat'
    get_data, 'L_SHELL', uts, dat
    store_data, var, uts, lshell2ilat(dat,/degree)
    settings = { $
        display_type: 'scalar', $
        unit: 'deg', $
        short_name: 'ILat'}
    add_setting, var, settings, /smart

    vars = ['L_SHELL','EDMLT_TIME','MAG_LATITUDE','GSM_POS']
    store_data, vars, /delete

end

time = time_double(['1996-12-25','1996-12-26'])
time = time_double(['1999-12-25','1999-12-26'])
polar_read_orbit, time
end
