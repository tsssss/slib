;+
; Read RBSP s/c velocity in GSM. Save as 'rbspx_v_gsm'
;
; time. A time or a time range in ut sec.
; probe. A string sets the probe, 'a' or 'b'.
;-
pro rbsp_read_sc_vel, time, probe=probe, errmsg=errmsg, _extra=ex

    ; read 'q_uvw2gsm'.
    rbsp_read_spice, time, id='sc_vel', probe=probe, coord='gsm', errmsg=errmsg, _extra=ex
    if errmsg ne '' then return

    prefix = 'rbsp'+probe+'_'
    var = prefix+'v_gsm'
    settings = { $
        display_type: 'vector', $
        unit: 'km/s', $
        short_name: 'V', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: sgcolor(['red','green','blue'])}
    add_setting, var, settings, /smart
    
    ; Remove overlapping times.
    get_data, var, times, data
    index = uniq(times, sort(times))
    store_data, var, times[index], data[index,*]

end
