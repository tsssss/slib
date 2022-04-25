;+
; Find the perigee using the given r_gsm data.
;
; posvar. A string, input, the variable saves r_gsm.
; times=. An array, output, the perigee times.
; period=. A number, output, orbital period in sec.
; perigee=. A number, output, the mean perigee distance.
; more_vars=. An array of string, input, filter these variables to the time of perigees.
;-

pro find_perigee, posvar, period=period, perigee=perigee, times=perigee_times, more_vars=mvars

    if n_elements(posvar) eq 0 then message, 'no pos info ...'
    get_data, posvar, uts, pos, limits=lim
    nrec = n_elements(uts)
    sz = size(pos,/dimensions)
    if n_elements(sz) eq 1 then dis = pos else dis = snorm(pos)
    dis = -dis  ; we flip dis, so that perigee can be found the same way as apogee.

    ; find perigee using derivative.
    df = dis[1:nrec-1]-dis[0:nrec-2]
    idx = where(df le 0, cnt)
    if cnt eq 0 then begin
        message, 'no perigee found ...', /continue
        return
    endif

    nodes = [1,df[0:nrec-3]*df[1:nrec-2],1] ; negative for node.
    idx0 = where(nodes le 0, nnode)
    flags = bytarr(nnode)       ; 1 for perigee, 0 for perigee.
    for i=0, nnode-1 do begin
        tdat = dis[(idx0[i]-5)>0:(idx0[i]+5)<(nrec-1)]
        if dis[idx0[i]] eq max(tdat) then flags[i] = 1 else $
        if dis[idx0[i]] eq min(tdat) then flags[i] = 0 else flags[i] = -1
    endfor

    idx = where(flags eq 1, cnt)
    idx1 = idx0[idx]
    tvar = posvar+'_perigee'
    store_data, tvar, uts[idx1], dis[idx1], limits=lim

    perigee_times = uts[idx1]
    period = sdatarate(perigee_times)
    perigee = mean(dis[idx1])

    if n_elements(mvars) eq 0 then return
    foreach tvar, mvars do begin
        get_data, tvar, tuts, tdat, limits=lim
        store_data, tvar+'_perigee', tuts[idx1], tdat[idx1], limits=lim
    endforeach

end
