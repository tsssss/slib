;+
; Filter based on the cwt_info.
;
; cwt_info. Calculated in calc_psd.
; filter=. The frequency range.
; index=. The frequency index.
;-

function wavelet_reconstruct, cwt_info, filter=filter, index=freq_index

    retval = !null
    if n_elements(cwt_info) eq 0 then return, retval

    s2t = cwt_info.s2t
    dj = cwt_info.dj
    cdelta = cwt_info.cdelta
    psi0 = cwt_info.psi0
    dt = cwt_info.dt

    s_j = cwt_info.s_j
    f_j = 1d/(s_j*s2t)
    rw_nj = real_part(cwt_info.w_nj)

    if n_elements(filter) eq 2 then index = lazy_where(f_j, filter)
    if n_elements(freq_index) ne 0 then index = freq_index
    
    count = n_elements(index)
    if count eq 0 then return, retval
    
    s_j = s_j[index]
    f_j = f_j[index]
    rw_nj = rw_nj[*,index]

    nj = n_elements(s_j)
    x_n = dblarr(cwt_info.n)
    for ii=0, nj-1 do x_n += rw_nj[*,ii]/sqrt(s_j[ii])
    coef = abs(dj*sqrt(dt)/(cdelta*psi0))
    x_n *= coef

    return, x_n

end
