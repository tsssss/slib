;+
; Make scales for wavelet transform.
;-
;

function wavelet_make_scale_calc_j, s0, sJ, dj
    return, round(alog2(sJ/s0)/dj)+1
end


function wavelet_make_scale, t_n, T=T, dt=dt, N=N, dj=dj, s0=s0, sJ=sJ, J=J

    ; To calc scale, one needs dj, and 2 of s0, sj, J.
    ; s0 can be set from dt, and sj can be set from T. Both dt, T can be set from t_n.
    if n_elements(dj) eq 0 then dj = 0.125d

    ; set t_n to get N, dt, T.
    ; or set 2 of N, dt, T and get the other one.
    if n_elements(t_n) ne 0 then begin
        dt = t_n[1]-t_n[0]
        N = n_elements(t_n)
        T = t_n[-1]-t_n[0]
    endif else begin
        if n_elements(dt) ne 0 and n_elements(T) ne 0 then N = T/dt
        if n_elements(N) ne 0 and n_elements(dt) ne 0 then T = N*dt
        if n_elements(T) ne 0 and n_elements(N) ne 0 then dt = T/N
    endelse
    
    ; set s0, sJ, dj, J.
    if n_elements(s0) eq 0 then s0 = 2d^(floor(alog2(2*dt)))
    if n_elements(sJ) eq 0 then sJ = 2d^(ceil(alog2(0.5*T)))
    if n_elements(J) eq 0 then J = wavelet_make_scale_calc_j(s0,sJ, dj)
    
    err = 1e-7
    if abs(J-round(J)) le err then begin
        if n_elements(dt) ne 0 then s0 = 2d^(floor(alog2(2*dt)))
        if n_elements(T) ne 0 then sJ = 2d^(ceil(alog2(0.5*T)))
        if n_elements(s0) ne 0 and n_elements(sJ) ne 0 then J = wavelet_make_scale_calc_j(s0,sJ, dj) else J = round(J)
    endif
    
    return, s0*2d^(findgen(J)*dj)

end

print, wavelet_make_scale([1,2,3,4,5,6,7,8])
end
