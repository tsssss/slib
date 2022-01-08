;+
; Convert a vector from GSE to mGSE.
;
; vec0. An array in [3] or [n,3]. In GSE, in any unit.
; times. An array of UT sec, in [n].
; wsc=. An array in [n,3]. The w-axis of the sc in GSE.
; probe=. A string of 'a' or 'b'. Doesn't need this if wsc is set.
; use_orig_quaternion=. Boolean, set to use the original quaternion from spice.
;
; mGSE is defined here http://www.space.umn.edu/wp-content/uploads/2013/11/MGSE_definition_RBSP_11_2013.pdf.
;-

function gse2mgse, vec0, time, wsc=wsc_gse, probe=probe, use_orig_quaternion=use_orig_quaternion
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
        if keyword_set(use_orig_quaternion) then begin
            if check_if_update(q_var, time_range) then rbsp_read_quaternion, time_range, probe=probe   ; original spice version.
        endif else begin
            if check_if_update(q_var, time_range) then rbsp_read_q_uvw2gse, time_range, probe=probe ; wobble-free version.
        endelse
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

    vx1 =  cosp*vx0 + sinp*vy0
    vy1 = -sinp*vx0 + cosp*vy0
    vz1 =  vz0
    vx2 =  sint*vx1 + cost*vz1
    vz2 = -cost*vx1 + sint*vz1

    vec1[0:n1-1] = temporary(vx2)
    vec1[n1:n2-1] = temporary(vy1)
    vec1[n2:n3-1] = temporary(vz2)
    return, vec1

end
