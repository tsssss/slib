;+
; Read quaternion to rotate from UVW to GSE. This is the original version from spice.
;
; time. The time or time range in UT sec.
; probe=. A string of 'a' or 'b'.
;-
pro rbsp_read_quaternion, time, probe=probe, errmsg=errmsg

    errmsg = ''

    ; read 'q_uvw2gse'.
    rbsp_read_spice, time, id='quaternion', probe=probe, errmsg=errmsg
    if errmsg ne '' then return

    coord = 'gse'
    prefix = 'rbsp'+probe+'_'
    var = prefix+'q_uvw2'+coord
    settings = { $
        spin_tone: 'raw', $
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
