;+
; Read MMS DC B field.
; Save data as 'mmsx_b_gsm'.
;-

pro mms_read_bfield, time, probe=probe, resolution=resolution, errmsg=errmsg

    resolution = (keyword_set(resolution))? strlowcase(resolution): 'survey'
    case resolution of
        'burst': message, 'Does not support burst yet ...'
        'survey': begin
            id = 'l2%survey'
            dt = 1d/16
        end
        else: message, 'Unknown resolution: '+resolution+' ...'
    endcase
    mms_read_fgm, time, id=id, probe=probe

    pre0 = 'mms'+probe+'_'
    bvar = pre0+'b_gsm'
    get_data, bvar, times, bgsm
    bgsm = bgsm[*,0:2]
    store_data, bvar, times, bgsm
    add_setting, bvar, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: sgcolor(['red','green','blue'])}
    uniform_time, bvar, dt

end

time = time_double(['2016-10-28/22:30:00','2016-10-29/01:00:00'])
mms_read_bfield, time, probe='1'
end
