;+
; Read DMSP bfield.
;-

function dmsp_read_bfield, input_time_range, probe=probe, errmsg=errmsg, coord=coord, get_name=get_name, _extra=ex

    prefix = 'dmsp'+probe+'_'
    errmsg = ''

    if n_elements(coord) eq 0 then coord = 'gsm'
    b_coord_var = prefix+'b_'+coord
    if keyword_set(get_name) then return, b_coord_var

    time_range = time_double(input_time_range)
    if ~check_if_update(b_coord_var, time_range) then return, b_coord_var

    files = dmsp_load_ssm_cdaweb(time_range, probe=probe, id='l2')
    if errmsg ne '' then return, retval

    coord_default = 'geo'
    b_default_var = prefix+'b_'+coord_default
    
;---Read data.
    var_list = list()
    ;in_vars = ['B_SC_OBS_ORIG','DELTA_B_SC_ORIG','DELTA_B_GEO']
    in_vars = ['DELTA_B_GEO']
    out_vars = b_default_var
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''
    

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


time_range = ['2013-05-01','2013-05-01/12:00']
probe = 'f18'
b_var = dmsp_read_bfield(time_range, probe=probe)
r_var = dmsp_read_orbit(time_range, probe=probe)

end