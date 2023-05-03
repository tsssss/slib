;+
; This is a pro version of the default IDL's smooth.
; The difference is that this version allows the smoothing width to change.
;
; xxs. The data. [n].
; wws. The widths, [n] or [1].
; edge_mirror=. Dummy.
; edge_truncate=. Dummy.
; edge_zero=. Set to fill 0 on edges.
; edge_fill-. Set the fill value on edges.
;-
function smooth_pro, xxs, wws, $
    edge_mirror=edge_mirror, edge_truncate=edge_truncate, $
    edge_zero=edge_zero, edge_fill=edge_fill
    
    fill_val = !null
    if keyword_set(edge_zero) then fill_val = 0.
    if n_elements(edge_fill) ne 0 then fill_val = edge_fill
    if n_elements(fill_val) eq 0 then auto_fill = 1

    nxx = n_elements(xxs)
    nww = n_elements(wws)
    if nww eq 1 then the_wws = fltarr(nxx)+wws[0] else the_wws = wws
    max_index = nxx-1
    
    sss = fltarr(nxx)
    buffer = []
    buffer_i0 = 0
    buffer_i1 = 0
    for ii=0,nxx-1 do begin
        ww = round(the_wws[ii])
        if ww le 1 then begin
            sss[ii] = xxs[ii]
            continue
        endif
        if ww mod 2 eq 0 then ww+= 1
        ww2 = ww*0.5
        i0 = ceil(ii-ww2)
        i1 = floor(i0+ww-1)
        j0 = i0>0
        j1 = i1<max_index
        if j0 gt j1 then continue
        buffer = xxs[j0:j1]
        if i0 lt j0 then begin
            if keyword_set(auto_fill) then fill_val = xxs[j0]
            pre_buffer = fltarr(j0-i0)+fill_val
            if keyword_set(edge_mirror) then pre_buffer = xxs[0:j0-i0-1]
            buffer = [pre_buffer,buffer]
        endif
        if i1 gt j1 then begin
            if keyword_set(auto_fill) then fill_val = xxs[j1]
            suf_buffer = fltarr(i1-j1)+fill_val
            if keyword_set(edge_mirror) then suf_buffer = xxs[nxx-i1+j1-1:nxx-1]
            buffer = [buffer,suf_buffer]
        endif
        sss[ii] = total(buffer)/ww
    endfor
    return, sss

end