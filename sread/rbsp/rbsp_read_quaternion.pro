;+
; Read quaternion to rotate from UVW to GSM.
;
; time. The time or time range in UT sec.
; probe=. A string of 'a' or 'b'.
;-
pro rbsp_read_quaternion, time, probe=probe, errmsg=errmsg, coord=coord

    errmsg = ''

    ; read 'q_uvw2gsm'.
    rbsp_read_spice, time, id='quaternion', probe=probe, errmsg=errmsg, coord=coord
    if errmsg ne '' then return

    pre0 = 'rbsp'+probe+'_'
    var = pre0+'q_uvw2'+coord
    settings = { $
        display_type: 'vector', $
        unit: '#', $
        short_name: 'Q', $
        coord: 'UVW2'+strupcase(coord), $
        coord_labels: ['a','b','c','d'], $
        colors: sgcolor(['red','green','blue','black'])}
    add_setting, var, settings, /smart
    
    ; Remove overlapping times.
    get_data, var, times, data
    index = uniq(times, sort(times))
    store_data, var, times[index], data[index,*]

end
