;+
; Read DMSP ion velocity.
;-

function dmsp_read_ion_vel, input_time_range, probe=probe, errmsg=errmsg, $
    coord=coord, get_name=get_name, update=update, _extra=ex

    prefix = 'dmsp'+probe+'_'
    errmsg = ''

    if n_elements(coord) eq 0 then coord = 'dmsp_xyz'
    coord_var = prefix+'v_'+coord
    if keyword_set(get_name) then return, coord_var

    time_range = time_double(input_time_range)
    if ~check_if_update(coord_var, time_range) then return, coord_var

    var = dmsp_read_ion_vel_madrigal(input_time_range, probe=probe, errmsg=errmsg)

    coord_default = 'dmsp_xyz'
    default_var = prefix+'v_'+coord_default


;---Calibrate the data.
    if coord ne coord_default then begin
        get_data, default_var, times, vec_default
        vec_coord = cotran(vec_default, times, coord_default+'2'+coord)
        store_data, coord_var, times, vec_coord
    endif
    add_setting, coord_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'vector', $
        'unit', 'km/s', $
        'short_name', 'V', $
        'coord', strupcase(coord) )

    return, coord_var

end