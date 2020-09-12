;+
; Read RBSP position in GSM. Save as 'rbspx_r_gsm'
;
; time. A time or a time range in ut sec.
; probe. A string sets the probe, 'a' or 'b'.
;-
pro rbsp_read_orbit, time, probe=probe, errmsg=errmsg, coord=coord, _extra=ex

    if n_elements(coord) eq 0 then coord = 'gse'
    ; read 'r_gse'.
    rbsp_read_spice, time, id='orbit', probe=probe, errmsg=errmsg, _extra=ex
    if errmsg ne '' then return
    
    ; Remove overlapping times.
    prefix = 'rbsp'+probe+'_'
    old_var = prefix+'r_gse'
    get_data, old_var, times, data
    index = uniq(times, sort(times))
    store_data, old_var, times[index], data[index,*]

    new_var = prefix+'r_'+coord
    if new_var ne old_var then begin
        data = get_var_data(old_var, times=times)
        data = cotran(data, times, 'gse2'+coord, probe=probe)
        store_data, new_var, times, data
        del_data, old_var
    endif
    settings = { $
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z'], $
        colors: sgcolor(['red','green','blue'])}
    add_setting, new_var, settings, /smart

end