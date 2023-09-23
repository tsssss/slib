;+
; Themis SPG to SMC. See definitions on P512 in the Themis mission book.
;
; SMC (Sensor Mechanical cood)
; SPG (Spinning Probe Geometrical coord)
;-

function themis_spg2themis_smc, vec_spg, times, probe=probe, errmsg=errmsg

    errmsg = ''
    retval = !null


    m_spg2smc0 = transpose(themis_get_m_smc2spg(probe=probe))
    ntime = n_elements(vec_spg[*,0])
    m_spg2smc = fltarr(ntime,3,3)    
    for ii=0,ntime-1 do m_spg2smc[ii,*,*] = m_spg2smc0

    vec_smc = rotate_vector(vec_spg, m_spg2smc)
    return, vec_smc

end