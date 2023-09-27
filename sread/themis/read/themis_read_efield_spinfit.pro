;+
; Read Themis E field in spinfit resolution (~3 sec).
;-

function themis_read_efield_spinfit, input_time_range, probe=probe, $
    get_name=get_name, coord=coord, keep_e56=keep_e56, edot0_e56=edot0_e56, _extra=ex


    prefix = 'th'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(coord) eq 0 then coord = 'themis_dsl'
    vec_coord_var = prefix+'e_'+coord
    if keyword_set(edot0_e56) then vec_coord_var = prefix+'edot0_'+coord
    if keyword_set(get_name) then return, vec_coord_var
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var

    ; Get E in DSL.
    default_coord = 'themis_dsl'
    vec_default_var = prefix+'e_'+default_coord
    if keyword_set(edot0_e56) then vec_default_var = prefix+'edot0_'+default_coord
    time_range = time_double(input_time_range)

    files = themis_load_efi(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()
    in_vars = prefix+'efs_dot0_dsl'
    time_var = prefix+'efs_dot0_time'
    out_vars = vec_default_var
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', time_var, $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''
    
    vec_default = get_var_data(vec_default_var, times=times)
    ; treat e56.
    if ~keyword_set(keep_e56) then vec_default[*,2] = 0
    if keyword_set(edot0_e56) then begin
        b_var = themis_read_bfield(time_range, probe=probe, coord=default_coord, id='fgs', errmsg=errmsg)
        if errmsg ne '' then return, retval
        interp_time, b_var, times
        b_vec = get_var_data(b_var)
        vec_default[*,2] = total(vec_default[*,0:1]*b_vec[*,0:1],2)/b_vec[*,2]
    endif
    store_data, vec_default_var, times, vec_default
    add_setting, vec_default_var, id='efield', dictionary('coord', default_coord)

    ; convert to wanted coord.
    if coord ne default_coord then begin
        msg = default_coord+'2'+coord
        e_coord = cotran_pro(vec_default, times, msg, probe=probe)
        store_data, vec_coord_var, times, e_coord
        add_setting, vec_coord_var, id='efield', dictionary('coord', coord)
    endif
    
    return, vec_coord_var

end

time_range = time_double(['2017-03-09/06:30','2017-03-09/09:00'])
probe = 'd'

prefix = 'th'+probe+'_'
edot0_var = themis_read_efield_spinfit(time_range, probe=probe, edot0_e56=1, coord='gsm')

end