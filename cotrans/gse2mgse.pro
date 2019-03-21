;+
; Convert a vector from GSE to mGSE.
;
; vec0. An array in [3] or [n,3]. In GSE, in any unit.
; times. An array of UT sec, in [n].
; wsc. An array in [n,3]. The w-axis of the sc in GSE.
; probe. A string of 'a' or 'b'. Doesn't need this if wsc is set.
;
; mGSE is defined here http://www.space.umn.edu/wp-content/uploads/2013/11/MGSE_definition_RBSP_11_2013.pdf.
;-

function gse2mgse, vec0, time, wsc=wsc, probe=probe
    compile_opt idl2 & on_error, 2

    vec1 = double(vec0)
    n1 = n_elements(vec1)/3 & n2 = n1+n1 & n3 = n2+n1
    vx0 = vec1[0:n1-1]
    vy0 = vec1[n1:n2-1]
    vz0 = vec1[n2:n3-1]

    ; get x_mgse, i.e., w_sc in gse.
    if n_elements(wsc) eq 0 then begin
        time_range = minmax(time)
        spice = sread_rbsp_spice_product(time_range, probe=probe)
        quvw2gsm = qslerp(spice.q_uvw2gsm, spice.ut_cotran, time)
        muvw2gsm = qtom(quvw2gsm)
        wsc_gsm = reform(muvw2gsm[*,*,2])
        wsc = cotran(wsc_gsm, time, 'gsm2gse')
    endif
    wx = wsc[*,0] & wy = wsc[*,1] & wz = wsc[*,2]

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