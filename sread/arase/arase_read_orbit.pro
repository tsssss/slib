;+
; Read Arase position in GSM. Save as 'arase_r_gsm'
;
; time. A time or a time range in ut sec.
;-
pro arase_read_orbit, time, errmsg=errmsg

    dt = 60.

    ; Use the predicted data because it's coverage is complete.
    ; Definitive data miss many dates, e.g., the beginning of 2017.
    id = 'l2%pre'
    arase_read_ssc, time, id=id

    rvar = 'arase_r_gsm'
    add_setting, rvar, /smart, {$
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: sgcolor(['red','green','blue'])}
    uniform_time, rvar, dt

end

time = time_double(['2017-01-01','2017-01-02'])
arase_read_orbit, time
end