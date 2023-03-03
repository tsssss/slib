;+
; Read RBSP s/c velocity in GSE. Save as 'rbspx_v_gse'
;
; time. A time or a time range in ut sec.
; probe. A string sets the probe, 'a' or 'b'.
;-
pro rbsp_read_sc_vel, time, probe=probe, coord=coord, errmsg=errmsg, _extra=ex

    if n_elements(coord) eq 0 then coord = 'gse'
    ; read 'v_gse'.
    rbsp_read_spice, time, id='sc_vel', probe=probe, errmsg=errmsg, _extra=ex
    if errmsg ne '' then return

    ; Remove overlapping times.
    prefix = 'rbsp'+probe+'_'
    old_var = prefix+'v_gse'
    get_data, old_var, times, data
    index = uniq(times, sort(times))
    store_data, old_var, times[index], data[index,*]
    
    new_var = prefix+'v_'+coord
    if new_var ne old_var then begin
        data = get_var_data(old_var, times=times)
        data = cotran(data, times, 'gse2'+coord, probe=probe)
        store_data, new_var, times, data
        del_data, old_var
    endif
    settings = { $
        display_type: 'vector', $
        unit: 'km/s', $
        short_name: 'V', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z'], $
        colors: sgcolor(['red','green','blue'])}
    add_setting, new_var, settings, /smart
    

end
