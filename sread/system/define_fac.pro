;+
; Define quaternion for rotation between FAC and the given coord.
; 
; b_var.
; r_var.
; time_var=.
;-

pro define_fac, b_var, r_var, time_var=time_var

    if n_elements(b_var) eq 0 then message, 'No b_var ...'
    if n_elements(r_var) eq 0 then message, 'No r_var ...'
    if tnames(b_var) eq '' then message, 'Invalid b_var ...'
    if tnames(r_var) eq '' then message, 'Invalid r_var ...'

    coord = get_setting(b_var, 'coord')
    if coord ne get_setting(r_var, 'coord') then $
        message, 'B and R are in different coord ...'


    if n_elements(time_var) eq 0 then time_var = r_var
    get_data, time_var, times

    bvec = get_var_data(b_var, at=times)
    rvec = get_var_data(r_var, at=times)

    rhat = sunitvec(rvec)
    bhat = sunitvec(bvec)
    what = sunitvec(vec_cross(rhat, bhat))
    ohat = vec_cross(bhat, what)

    ntime = n_elements(times)
    ndim = 3
    m_xxx2fac = fltarr(ntime,ndim,ndim)
    m_xxx2fac[*,0,*] = bhat
    m_xxx2fac[*,1,*] = what
    m_xxx2fac[*,2,*] = ohat
    q_xxx2fac = mtoq(m_xxx2fac)

    pre0 = get_prefix(b_var)
    q_var = pre0+'q_'+strlowcase(coord)+'2fac'
    store_data, q_var, times, q_xxx2fac

    coord_labels = get_setting(b_var, 'coord_labels')
    fac_labels = ['b','w','o']
    add_setting, q_var, {$
        in_coord: coord, $
        in_coord_labels: coord_labels, $
        out_coord: 'FAC', $
        out_coord_labels: fac_labels}


end
