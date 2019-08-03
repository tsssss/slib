
pro rbsp_gsm2uvw, ivar, ovar, quaternion=qvar

    if n_elements(output_var) eq 0 then output_var = ivar+'_uvw'
    get_data, ivar, uts, vec0

    pre0 = get_prefix(ivar)
    probe = strmid(pre0, 1,1, /reverse)

    if n_elements(qvar) eq 0 then qvar = pre0+'q_uvw2gsm'
    if tnames(qvar) eq '' then rbsp_read_quaternion, minmax(uts), probe=probe

    get_data, qvar, tuts, quvw2gsm
    if n_elements(tuts) ne n_elements(uts) then $
        quvw2gsm = qslerp(quvw2gsm, tuts, uts)
    muvw2gsm = qtom(quvw2gsm)
    nrec = n_elements(uts)
    for ii=0, nrec-1 do muvw2gsm[ii,*,*] = transpose(muvw2gsm[ii,*,*])

    vec1 = rotate_vector(vec0, muvw2gsm)
    store_data, ovar, uts, vec1
    add_setting, ovar, /smart, {$
        display_type: 'vector', $
        unit: get_setting(ivar, 'unit'), $
        short_name: get_setting(ivar, 'short_name'), $
        coord: 'UVW', $
        coord_labels: ['u','v','w'], $
        colors: get_setting(ivar, 'colors')}

end

time = time_double(['2019-04-10/12:48','2019-04-10/13:48'])
probe = 'b'
rbsp_read_orbit, time, probe=probe
rbsp_read_quaternion, time, probe=probe

pre0 = 'rbsp'+probe+'_'
rbsp_gsm2uvw, pre0+'r_gsm', pre0+'r_uvw'
rbsp_uvw2gsm, pre0+'r_uvw', pre0+'r1_gsm'
end
