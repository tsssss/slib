
pro rbsp_uvw2gsm, ivar, ovar, quaternion=qvar

    if n_elements(output_var) eq 0 then output_var = ivar+'_gsm'
    get_data, ivar, uts, vec0
    
    pre0 = get_prefix(ivar)
    probe = strmid(pre0, 1,1, /reverse)
    
    if n_elements(qvar) eq 0 then qvar = pre0+'q_uvw2gsm'
    
    if tnames(qvar) eq '' then $
        rbsp_load_quaternion, minmax(uts), probe
    
    get_data, qvar, tuts, quvw2gsm
    if n_elements(tuts) ne n_elements(uts) then $
        quvw2gsm = qslerp(quvw2gsm, tuts, uts)
    muvw2gsm = qtom(quvw2gsm)
    
    vec1 = rotate_vector(vec0, muvw2gsm)
    store_data, ovar, uts, vec1
    add_setting, ovar, /smart, {$
        display_type: 'vector', $
        unit: get_setting(ivar, 'unit'), $
        short_name: get_setting(ivar, 'short_name'), $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: get_setting(ivar, 'colors')}

end