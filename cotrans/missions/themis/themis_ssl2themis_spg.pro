;+
; Themis SSL to SPG. See definitions on P512 in the Themis mission book.
;
; SPG (Spinning Probe Geometrical coord)
; SSL (Spin-sun Sensor L-vectorZ coord)
;-

function themis_ssl2themis_spg, vec_ssl, times, probe=probe, errmsg=errmsg

    errmsg = ''
    retval = !null


    ; Table 1 on P513 in the Themis mission book.
    m_ssl2spg0 = transpose(themis_get_m_spg2ssl(probe=probe))

    ntime = n_elements(vec_ssl[*,0])
    m_ssl2spg = fltarr(ntime,3,3)    
    for ii=0,ntime-1 do m_ssl2spg[ii,*,*] = m_ssl2spg0

    vec_spg = rotate_vector(vec_ssl, m_ssl2spg)
    return, vec_spg

end