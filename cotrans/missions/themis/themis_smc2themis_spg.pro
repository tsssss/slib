;+
; Themis SMC to SPG. See definitions on P512 in the Themis mission book.
;
; SMC (Sensor Mechanical cood)
; SPG (Spinning Probe Geometrical coord)
;-

function themis_smc2themis_spg, vec_smc, times, probe=probe, errmsg=errmsg

    errmsg = ''
    retval = !null


    m_smc2spg0 = themis_get_m_smc2spg(probe=probe)
    ntime = n_elements(vec_smc[*,0])
    m_smc2spg = fltarr(ntime,3,3)    
    for ii=0,ntime-1 do m_smc2spg[ii,*,*] = m_smc2spg0

    vec_spg = rotate_vector(vec_smc, m_smc2spg)
    return, vec_spg

end