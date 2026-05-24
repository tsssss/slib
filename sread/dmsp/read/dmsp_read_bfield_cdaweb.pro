;+
; Read DMSP bfield.
;-

function dmsp_read_bfield_cdaweb, input_time_range, probe=probe, errmsg=errmsg, coord=coord, get_name=get_name, get_b0=get_b0, suffix=suffix, _extra=ex

    prefix = 'dmsp'+probe+'_'
    errmsg = ''
    retval = !null

    if n_elements(suffix) eq 0 then suffix = '_cdaweb'
    if n_elements(coord) eq 0 then coord = 'dmsp_xyz'
    b_coord_var = prefix+'db_'+coord+suffix
    if keyword_set(get_name) then return, b_coord_var

    time_range = time_double(input_time_range)
    if ~check_if_update(b_coord_var, time_range) then return, b_coord_var

    files = dmsp_load_ssm_cdaweb(time_range, probe=probe, id='l2')
    if errmsg ne '' then return, retval

;    coord_default = 'geo'
    coord_default = 'dmsp_xyz'
    b_default_var = prefix+'db_'+coord_default+suffix
    if keyword_set(get_b0) then b_default_var = prefix+'b_'+coord_default+suffix

    
;---Read data.
    ; The delta_b_geo has the baseline removal.
    ; But to keep the data same as _noaa and _madrigal, we read delta_b_sc_orig.
    var_list = list()
    ;in_vars = ['B_SC_OBS_ORIG','DELTA_B_SC_ORIG','DELTA_B_GEO']
    ;in_vars = ['DELTA_B_GEO']
    if keyword_set(get_b0) then begin
        in_vars = ['B_SC_OBS_ORIG']
    endif else begin
        in_vars = ['DELTA_B_SC_ORIG']
    endelse
    out_vars = b_default_var
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''
    

;---Calibrate the data.
    vec_default = var_get_data(b_default_var, times=times)
    vec_default = vec_default[*,[1,2,0]]
    if coord ne coord_default then begin
        vec_coord = cotran(vec_default, times, coord_default+'2'+coord)
    endif
    store_data, b_coord_var, times, vec_coord
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
b_var = dmsp_read_bfield_cdaweb(time_range, probe=probe)
b_var2 = dmsp_read_bfield_madrigal(time_range, probe=probe)
b_var3 = dmsp_read_bfield_noaa(time_range, probe=probe)
r_var = dmsp_read_orbit(time_range, probe=probe)

end