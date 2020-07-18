;+
; Read RBSP position in GSM. Save as 'rbspx_r_gsm'
;
; time. A time or a time range in ut sec.
; probe. A string sets the probe, 'a' or 'b'.
;-
pro rbsp_read_orbit, time, probe=probe, errmsg=errmsg, coord=coord, _extra=ex

    if n_elements(coord) eq 0 then coord = 'gsm'
    ; read 'q_uvw2gsm'.
    rbsp_read_spice, time, id='orbit', probe=probe, coord=coord, errmsg=errmsg, _extra=ex
    if errmsg ne '' then return

    pre0 = 'rbsp'+probe+'_'
    var = pre0+'r_'+coord
    settings = { $
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z'], $
        colors: sgcolor(['red','green','blue'])}
    add_setting, var, settings, /smart
    
    ; Remove overlapping times.
    get_data, var, times, data
    index = uniq(times, sort(times))
    store_data, var, times[index], data[index,*]

end
