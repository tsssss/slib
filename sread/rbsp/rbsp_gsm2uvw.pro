;+
; Rotate a 3D vector in GSM to UVW.
;-
pro rbsp_gsm2uvw, ivar, ovar, quaternion=qvar, probe=probe

    if n_elements(ovar) eq 0 then ovar = ivar+'_uvw'
    get_data, ivar, times, ivec

    pre0 = get_prefix(ivar)
    if n_elements(qvar) eq 0 then qvar = pre0+'q_uvw2gsm'

    if n_elements(probe) eq 0 then probe = strmid(pre0, 1,1, /reverse)
    time_range = minmax(times)
    if check_if_update(qvar, time_range) then rbsp_read_quaternion, time_range, probe=probe

    get_data, qvar, uts, quvw2gsm
    nrec = n_elements(times)
    if n_elements(uts) ne nrec then quvw2gsm = qslerp(quvw2gsm, uts, times)
    muvw2gsm = qtom(quvw2gsm)
    for ii=0, nrec-1 do muvw2gsm[ii,*,*] = transpose(muvw2gsm[ii,*,*])
    mgsm2uvw = temporary(muvw2gsm)

    ovec = rotate_vector(ivec, mgsm2uvw)
    store_data, ovar, uts, ovec
    colors = get_setting(ivar, 'colors', exist)
    if ~exist then colors = sgcolor(['red','green','blue'])
    unit = get_setting(ivar, 'unit', exist)
    if ~exist then unit = 'xxx'
    short_name = get_setting(ivar, 'short_name', exist)
    if ~exist then short_name = ''
    add_setting, ovar, /smart, {$
        display_type: 'vector', $
        unit: unit, $
        short_name: short_name, $
        coord: 'UVW', $
        coord_labels: ['u','v','w'], $
        colors: colors}

end

time = time_double(['2019-04-10/12:48','2019-04-10/13:48'])
probe = 'b'
rbsp_read_orbit, time, probe=probe
rbsp_read_quaternion, time, probe=probe

pre0 = 'rbsp'+probe+'_'
rbsp_gsm2uvw, pre0+'r_gsm', pre0+'r_uvw'
rbsp_uvw2gsm, pre0+'r_uvw', pre0+'r1_gsm'
end
