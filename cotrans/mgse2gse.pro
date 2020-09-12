;+
; Convert a vector from mGSE to GSE.
;
; vec0. An array in [3] or [n,3]. In mGSM, in any unit.
; times. An array of UT sec, in [n].
; wsc. An array in [n,3]. The w-axis of the sc in GSE.
; probe. A string of 'a' or 'b'. Doesn't need this if wsc is set.
;
; mGSE is defined here http://www.space.umn.edu/wp-content/uploads/2013/11/MGSE_definition_RBSP_11_2013.pdf.
;-

function mgse2gse, vec0, time, wsc=wsc_gse, probe=probe, _extra=ex
    compile_opt idl2 & on_error, 2

    vec1 = double(vec0)
    n1 = n_elements(vec1)/3 & n2 = n1+n1 & n3 = n2+n1
    vx0 = vec1[0:n1-1]
    vy0 = vec1[n1:n2-1]
    vz0 = vec1[n2:n3-1]

    ; get x_mgse, i.e., w_sc in gse.
    if n_elements(wsc_gse) eq 0 then begin
        time_range = minmax(time)
        if n_elements(probe) eq 0 then message, 'Needs probe ...'
        prefix = 'rbsp'+probe+'_'
        q_var = prefix+'q_uvw2gse'
        if check_if_update(q_var, time_range) then rbsp_read_quaternion, time_range, probe=probe
        q_uvw2gse = get_var_data(q_var, times=ut_cotran)
        quvw2gse = qslerp(q_uvw2gse, ut_cotran, time)
        muvw2gse = qtom(quvw2gse)
        wsc_gse = reform(muvw2gse[*,*,2])
    endif
    wx = wsc_gse[*,0] & wy = wsc_gse[*,1] & wz = wsc_gse[*,2]

    ; do rotation.
    p = atan(double(wy),wx)     ; this way p (phi) in [0,2pi].
    cosp = cos(p)
    sint = wx/cosp
    sinp = wy/sint
    cost = double(wz)

    vx1 = sint*vx0 - cost*vz0
    vz1 = cost*vx0 + sint*vz0
    vy1 = vy0
    vx2 = cosp*vx1 - sinp*vy1
    vy2 = sinp*vx1 + cosp*vy1

    vec1[0:n1-1] = temporary(vx2)
    vec1[n1:n2-1] = temporary(vy2)
    vec1[n2:n3-1] = temporary(vz1)
    return, vec1

end
