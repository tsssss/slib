;+
; Read Themis position. Default is to read 'pos@gsm'.
;-

pro themis_read_orbit, time, probe=probe, errmsg=errmsg, _extra=ex

    pre0 = 'th'+probe+'_'
    dt = 60.0

    ; read 'xyz_gsm'
    themis_read_ssc, time, id='pos', probe=probe, errmsg=errmsg, _extra=ex

    var = pre0+'r_gsm'
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: 'GSM', $
        coord_labels: constant('xyz')}

    uniform_time, var, dt

end
