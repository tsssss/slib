;+
; MMS FCS to BCS
; c.f. mms_feeps_pitch_angles.pro.
;-

function mms_fcs2mms_bcs, vec_fcs, times, probe=probe, errmsg=errmsg
    errmsg = ''
    retval = !null
    
    m_fcs2bcs0 = mms_get_m_bcs2fcs()
    ntime = n_elements(vec_fcs[*,0])
    ndim = 3
    dims = [ntime,ndim,ndim]
    m_fcs2bcs = reform((fltarr(ntime)+1) # m_fcs2bcs0[*], dims)

    vec_bcs = rotate_vector(float(vec_fcs), m_fcs2bcs)
    return, vec_bcs

end

m_fcs2bcs0 = mms_get_m_bcs2fcs()
print, mms_fcs2mms_bcs((fltarr(1)+1) # [1,0,0])-m_fcs2bcs0[*,0]
print, mms_fcs2mms_bcs((fltarr(1)+1) # [0,1,0])-m_fcs2bcs0[*,1]
print, mms_fcs2mms_bcs((fltarr(1)+1) # [0,0,1])-m_fcs2bcs0[*,2]
end
