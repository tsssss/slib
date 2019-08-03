;+
; Read LANL orbit.
; Save 'xxx_r_gsm' to memory.
;-

pro lanl_read_orbit, time_range, probe=probe, errmsg=errmsg

    errmsg = ''
    pre0 = probe+'_'

    ; read 'pre_r_geo'.
    lanl_read_data, time_range, id='orbit', probe=probe

    vars = 'r_geo'
    fillval = -1e31
    nan = !values.f_nan
    foreach var, vars do begin
        if tnames(var) eq '' then continue
        get_data, var, times, data
        index = where(data eq fillval, count)
        if count ne 0 then data[index] = nan
        store_data, var, times, data
    endforeach


    get_data, 'r_geo', times, r_geo
    r_gsm = cotran(r_geo, times, 'geo2gsm')

    var = pre0+'r_gsm'
    store_data, var, times, r_gsm
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: sgcolor(['red','green','blue'])}

;    vars = ['mlon','mlat','mlt','glat','glon']
;    foreach var, vars do begin
;        if tnames(var) eq '' then continue
;        rename_var, var, to=pre0+var
;    endforeach

end

time = time_double(['2014-08-28','2014-08-29'])
probes = ['LANL-'+['01A','02A','04A','97A'],'1991-080','1994-084']
foreach probe, probes do lanl_read_orbit, time, probe=probe
end
