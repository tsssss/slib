;+
;-
pro themis_read_ion_vel, time, probe=probe, $
    resolution=resolution, coord=coord, errmsg=errmsg

    pre0 = 'th'+probe+'_'
    if n_elements(coord) eq 0 then coord = 'gsm'
    resolution = (keyword_set(keyword))? strlowcase(resolution): '3sec'
    case resolution of
        '3sec': begin
            dt = 3
            data_type = 'l2%ion_u_gsm'
        end
    endcase

    ; read 'thx_ele_n'
    themis_read_esa, time, id=data_type, probe=probe, errmsg=errmsg
    if errmsg ne '' then return

    var = pre0+'u_gsm'
    get_data, var, times, data
    index = where(data le -1e30, count)
    if count ne 0 then begin
        data[index] = !values.d_nan
        store_data, var, times, data
    endif
    if coord ne 'gsm' then begin
        get_data, var, times, vec
        vec = cotran(vec, times, 'gsm2'+coord)
        var = pre0+'u_'+coord
        store_data, var, times, vec
    endif
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'km/s', $
        short_name: 'U!S!Uion!N!R', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z'], $
        colors: sgcolor(['red','green','blue'])}

end

time = time_double(['2014-08-28','2014-08-29'])
probe = 'a'
themis_read_ion_vel, time, probe=probe
end