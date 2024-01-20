;+
; Read DMSP ion velocity.
;-

function dmsp_read_ion_vel, input_time_range, probe=probe, errmsg=errmsg, $
    coord=coord, get_name=get_name, update=update, _extra=ex

    prefix = 'dmsp'+probe+'_'
    errmsg = ''

    if n_elements(coord) eq 0 then coord = 'gsm'
    b_coord_var = prefix+'b_'+coord
    if keyword_set(get_name) then return, b_coord_var

    time_range = time_double(input_time_range)
    if ~check_if_update(b_coord_var, time_range) then return, b_coord_var

    var = dmsp_read_ion_vel_madrigal(input_time_range, probe=probe, errmsg=errmsg)

    coord_default = 'dmsp_xyz'
    default_var = prefix+'b_'+coord_default


;---Calibrate the data.
    if coord ne coord_default then begin
        get_data, b_default_var, times, vec_default
        vec_coord = cotran(vec_default, times, coord_default+'2'+coord)
        store_data, b_coord_var, times, vec_coord
    endif
    add_setting, b_coord_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', strupcase(coord) )

    return, b_coord_var

end