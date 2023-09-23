;+
; Themis SPG to SSL. See definitions on P512 in the Themis mission book.
;
; SPG (Spinning Probe Geometrical coord)
; SSL (Spin-sun Sensor L-vectorZ coord)
;-

function themis_spg2themis_ssl, vec_spg, times, probe=probe, errmsg=errmsg

    errmsg = ''
    retval = !null


    m_spg2ssl0 = themis_get_m_spg2ssl(probe=probe)
    ntime = n_elements(vec_spg[*,0])
    m_spg2ssl = fltarr(ntime,3,3)    
    for ii=0,ntime-1 do m_spg2ssl[ii,*,*] = m_spg2ssl0

    vec_ssl = rotate_vector(vec_spg, m_spg2ssl)
    return, vec_ssl

end