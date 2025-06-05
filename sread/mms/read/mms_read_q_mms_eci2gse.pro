function mms_read_q_mms_eci2gse, input_time_range, probe=probe, errmsg=errmsg
    var_info=var_info, $
    errmsg=errmsg, get_name=get_name, update=update, suffix=suffix
    
    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = !null

    ; Prepare var name.
    if n_elements(suffix) eq 0 then suffix = ''
    if n_elements(var_info) eq 0 then var_info = prefix+'q_mms_eci2gse'+suffix
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then tmp = delete_var_from_memory(var_info)
    time_range = time_double(input_time_range)
    if ~check_if_update_memory(var_info, time_range) then return, var_info
    
    files = mms_ld_mec(time_range, id='l2%survey', probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    in_var = prefix+'mec_quat_eci_to_gse'
    var_list = list()
    var_list.add, dictionary($
        'in_vars', in_var, $
        'out_vars', var_info, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    
    quaternion = get_var_data(var_info, times=times)
    quaternion = quaternion[*,[3,0,1,2]]  ; mms quaternion in <x,y,z,w>, need to convert to <w,x,y,z>.
    var_info = var_store(var_info, quaternion, times)
    eq_tolerance = 1e-8
    add_setting, var_info, smart=1, id='quaternion', dictionary($
        'requested_time_range', time_range, $
        'eq_tolerance', eq_tolerance, $
        'coord', 'mms_eci2gse')

    return, var_info
end