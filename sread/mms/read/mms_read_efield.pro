;+
; Read E field.
;-

function mms_read_efield, input_time_range, id=datatype, probe=probe, $
    errmsg=errmsg, coord=coord, get_name=get_name, update=update, _extra=ex

    errmsg = ''
    retval = ''

    if ~mms_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'mms'+probe+'_'

    ; Prepare var name.
    default_coord = 'mms_dsl'
    default_coord = 'gse'
    if n_elements(coord) eq 0 then coord = default_coord
    var_info = prefix+'e_'+coord
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info
    vec_default_var = prefix+'e_'+default_coord

    ; Load files.
    files = mms_ld_edp(time_range, probe=probe, id='l2%fast%dce', errmsg=errmsg)
    if errmsg ne '' then return, retval

;---Read data.
    var_list = list()
    in_vars = [prefix+'edp_dce_dsl_fast_l2']
    in_vars = [prefix+'edp_dce_gse_fast_l2']
    out_vars = [vec_default_var]
    time_var = prefix+'edp_epoch_fast_l2'
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', time_var, $
        'time_var_type', 'tt2000' )

    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''
    add_setting, vec_default_var, id='efield', dictionary($
        'mission', 'mms', $
        'probe', probe, $
        'requested_time_range', time_range, $
        'coord', default_coord )
    
;---Calibrate the data.
    get_data, vec_default_var, times, vec_default
    index = where(abs(vec_default) ge 1e10, count)
    if count ne 0 then begin
        vec_default[index] = !values.f_nan
        store_data, vec_default_var, times, vec_default
    endif
    
    ; Convert to wanted coord.
    if coord ne default_coord then begin
        get_data, vec_default_var, times, vec_default, limits=lim
        vec_coord = cotran_pro(vec_default, times, coord_msg=[default_coord,coord], probe=probe)
        store_data, var_info, times, vec_coord, limits=lim
    endif
    
    add_setting, var_info, id='efield', dictionary($
        'requested_time_range', time_range, $
        'coord', coord )
    
    return, var_info

end