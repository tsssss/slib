;+
; Read GOES position.
;-

pro goes_read_orbit, time, probe=probe, errmsg=errmsg

    pre0 = 'g'+probe+'_'
    dt = 60.0

    ; read 'xyz_gsm'
    goes_read_ssc, time, id='pos', probe=probe, errmsg=errmsg

    var = pre0+'r_gsm'
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: 'GSM', $
        coord_labels: constant('xyz')}

    uniform_time, var, dt

end

time = time_double(['2013-01-01','2013-01-02'])
goes_read_orbit, time, probe='13'
end