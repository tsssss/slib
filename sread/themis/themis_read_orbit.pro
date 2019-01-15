;+
; Read Themis position. Default is to read 'pos@gsm'.
;-

pro themis_read_orbit, utr0, probe=probe, errmsg=errmsg, _extra=ex

    pre0 = 'th'+probe+'_'
    dt = 60.0
    
    ; read 'xyz_gsm'
    themis_read_ssc, utr0, 'pos@gsm', probe=probe, errmsg=errmsg, _extra=ex

    var = pre0+'r_gsm'
    rename_var, 'xyz_gsm', to=var
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: [6,4,2]}

    uniform_time, var, dt

end
