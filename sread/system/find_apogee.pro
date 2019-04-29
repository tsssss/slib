;+
; Find the apogee using the given r_gsm data.
;
; posvar. A string of the variable saves r_gsm.
; apogee_times. An array of the apogee times.
; period. A number, output, orbital period in sec.
; apogee. A number, output, the mean apogee distance.
; more_vars. An array of string, input, filter these variables to the time of apogees.
;-

pro find_apogee, posvar, period=period, apogee=apogee, apogee_times=apogee_times, more_vars=mvars

    if n_elements(posvar) eq 0 then message, 'no pos info ...'
    get_data, posvar, uts, pos, limits=lim
    nrec = n_elements(uts)
    sz = size(pos,/dimensions)
    if n_elements(sz) eq 1 then dis = pos else dis = snorm(pos)

    ; find apogee using derivative.
    df = dis[1:nrec-1]-dis[0:nrec-2]
    idx = where(df le 0, cnt)
    if cnt eq 0 then begin
        message, 'no apogee found ...', /continue
        return
    endif

    nodes = [1,df[0:nrec-3]*df[1:nrec-2],1] ; negative for node.
    idx0 = where(nodes le 0, nnode)
    flags = bytarr(nnode)       ; 1 for apogee, 0 for perigee.
    for i=0, nnode-1 do begin
        tdat = dis[(idx0[i]-5)>0:(idx0[i]+5)<(nrec-1)]
        if dis[idx0[i]] eq max(tdat) then flags[i] = 1 else $
        if dis[idx0[i]] eq min(tdat) then flags[i] = 0 else flags[i] = -1
    endfor

    idx = where(flags eq 1, cnt)
    idx1 = idx0[idx]
    tvar = posvar+'_apogee'
    store_data, tvar, uts[idx1], dis[idx1], limits=lim

    apogee_times = uts[idx1]
    period = sdatarate(apogee_times)
    apogee = mean(dis[idx1])

    if n_elements(mvars) eq 0 then return
    foreach tvar, mvars do begin
        get_data, tvar, tuts, tdat, limits=lim
        store_data, tvar+'_apogee', tuts[idx1], tdat[idx1], limits=lim
    endforeach

end
