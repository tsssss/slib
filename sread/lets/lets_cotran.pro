
function lets_cotran, coord_msgs, input=in_var, output=out_var, q_var=q_var, $
    update=update, get_name=get_name, suffix=suffix, errmsg=errmsg, $
    save_to=data_file, time_var=time_var


    errmsg = ''
    retval = !null

    var_info = out_var
    ; Check if update in memory.
    if keyword_set(update) then tmp = delete_var_from_memory(var_info)
    if ~check_if_update_memory(var_info, time_range) then return, var_info

    ; Check if loading from file.
    if keyword_set(update) then tmp = delete_var_from_file(var_info, file=data_file, errmsg=errmsg)
    is_success = read_var_from_file(var_info, file=data_file, errmsg=errmsg)
    if is_success then return, var_info


    out_coord = coord_msgs[1]
    if out_coord eq 'fac' then begin
        if n_elements(q_var) eq 0 then begin
            errmsg = 'No quaternion ...'
            return, retval
        endif
        in_coord = coord_msgs[0]
        q_in_coord = get_setting(q_var, 'in_coord')
        if in_coord ne q_in_coord then begin
            the_in_var = streplace(in_var, in_coord, q_in_coord)
            the_in_var = lets_cotran([in_coord,q_in_coord], input=in_var, output=the_in_var)
        endif else begin
            the_in_var = in_var
        endelse

        get_data, the_in_var, times, vec
        ntime = n_elements(times)
        get_data, q_var, qtimes, q_xxx2fac
        if ntime ne n_elements(qtimes) then q_xxx2fac = qslerp(q_xxx2fac, qtimes, times)
        m_xxx2fac = qtom(q_xxx2fac)
        vec = rotate_vector(vec, m_xxx2fac)

        store_data, out_var, times, vec
        add_setting, out_var, /smart, {$
            display_type: 'vector', $
            short_name: get_setting(in_var,'short_name'), $
            unit: get_setting(in_var,'unit'), $
            coord: 'fac', $
            coord_labels: get_setting(q_var,'out_coord_labels')}
    endif else begin
        in_vec = get_var_data(in_var, times=times, settings=settings)
        probe = get_var_setting(in_var, 'probe')
        
        out_vec = cotran_pro(in_vec, times, coord_msg=coord_msgs, probe=probe)
        store_data, out_var, times, out_vec
        out_coord = coord_msgs[1]
        settings['coord'] = out_coord
        add_setting, out_var, smart=1, settings
    endelse


    ; Save to file.
    if n_elements(data_file) ne 0 then begin
        is_success = save_var_to_file(var_info, file=data_file, time_var=time_var)
    endif

    return, var_info
    
end