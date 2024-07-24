;+
; MMS BCS to MCS.
; c.f. mms_feeps_pitch_angles.pro.
;-

function ct_mms_bcs2mms_fcs, vec_bcs, times, probe=probe, errmsg=errmsg
    errmsg = ''
    retval = !null
    
    m_bcs2fcs0 = transpose(mms_get_m_bcs2fcs())
    ntime = n_elements(vec_bcs[*,0])
    ndim = 3
    dims = [ntime,ndim,ndim]
    m_bcs2fcs = reform((fltarr(ntime)+1) # m_bcs2fcs0[*], dims)
;    m_bcs2fcs = fltarr(ntime,3,3)
;    for ii=0,2 do for jj=0,2 do m_bcs2fcs[*,ii,jj] = m_bcs2fcs0[ii,jj]

    vec_fcs = rotate_vector(float(vec_bcs), m_bcs2fcs)
    return, vec_fcs

end

m_bcs2fcs0 = transpose(mms_get_m_bcs2fcs())
print, ct_mms_bcs2mms_fcs((fltarr(1)+1) # [1,0,0])-m_bcs2fcs0[*,0]
print, ct_mms_bcs2mms_fcs((fltarr(1)+1) # [0,1,0])-m_bcs2fcs0[*,1]
print, ct_mms_bcs2mms_fcs((fltarr(1)+1) # [0,0,1])-m_bcs2fcs0[*,2]
end