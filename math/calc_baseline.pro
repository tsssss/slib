
function calc_baseline, asi_raw, window, times

    if n_elements(times) eq 0 then times = findgen(n_elements(asi_raw))
    
    ; Truncate data into sectors of the wanted window
    nframe = n_elements(asi_raw)
    sec_times = make_bins(minmax(times), window, inner=1)
    time_step = times[1]-times[0]
    sec_pos = (sec_times-times[0])/time_step
    nsec = n_elements(sec_pos)-1
    frames = dindgen(nframe)

    ; Get the min value within each sector.
    xxs = fltarr(nsec)
    yys = fltarr(nsec)
    for kk=0,nsec-1 do begin
        yys[kk] = min(asi_raw[sec_pos[kk]:sec_pos[kk+1]-1], index)
        ;xxs[kk] = sec_pos[kk]+index  ; This causes weird result.
        xxs[kk] = (sec_pos[kk]+sec_pos[kk+1])*0.5
    endfor
;    ; Add sample points at the beginning and end of the raw data.
    txs = frames[sec_pos[0]:sec_pos[1]]
    tys = asi_raw[sec_pos[0]:sec_pos[1]]
    res = linfit(txs,tys)
    ty = (yys[0]-(xxs[0]-0)*res[1])>min(tys)
    xxs = [0,xxs]
    yys = [ty,yys]
    
    txs = frames[sec_pos[-2]:sec_pos[-1]]
    tys = asi_raw[sec_pos[-2]:sec_pos[-1]]
    res = linfit(txs,tys)
    ty = (yys[-1]+(nframe-1-xxs[-1])*res[1])>min(tys)

    ; Smooth after interpolation to make the background continuous.
    time_bg = smooth(interpol(yys,xxs,frames), window*0.5, edge_mirror=1)
    return, time_bg

end