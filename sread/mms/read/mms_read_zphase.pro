

function mms_read_zphase, input_time_range, probe=probe, $
    var_info=var_info, $
    errmsg=errmsg, get_name=get_name, update=update, suffix=suffix

    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = !null

    ; Prepare var name.
    if n_elements(suffix) eq 0 then suffix = ''
    if n_elements(var_info) eq 0 then var_info = prefix+'zphase'+suffix
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then tmp = delete_var_from_memory(var_info)
    time_range = time_double(input_time_range)
    if ~check_if_update_memory(var_info, time_range) then return, var_info

    files = mms_ld_state_data(time_range, id='defatt', probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    times = []
    zphase = []
    vars = ['z_phase']
    foreach file, files do begin
        data_info = mms_read_def_att(vars, filename=file)
        the_times = data_info['time']
        time_index = where_pro(the_times, '[]', time_range, count=count)
        if count eq 0 then continue
        times = [times, the_times[time_index]]
        zphase = [zphase, (data_info['z_phase'])[time_index]]
    endforeach

    settings = dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'deg', $
        'short_name', 'Z Phase' )
    time_index = sort_uniq(times,index=1)
    times = times[time_index]
    data = zphase[time_index]
    var_info = var_store(var_info, data, times, settings=settings)
    
    return, var_info

end