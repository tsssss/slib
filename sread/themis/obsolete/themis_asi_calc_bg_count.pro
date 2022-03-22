;+
; Calculate the background count for given asi image.
;
; imgs. Input images in [n,x,y].
; window=. Window for background calculation in sec. By default is 15 min.
;-
function themis_asi_calc_bg_count, imgs, window=window

    img_size = size(reform(imgs[0,*,*]),dimensions=1)
    ntime = n_elements(imgs[*,0,0])

    time_step = 3   ; sec.    
    window1 = 15*60d ; sec.
    width1 = window1/time_step
    window2 = 30d   ; sec.
    width2 = window2/time_step
    
    if keyword_set(window) then begin
        window1 = window
        width1 = window1/time_step
    endif
    
    if ntime le width1 then begin
        imgs_bg0 = fltarr(img_size)
        for ii=0,img_size[0]-1 do begin
            for jj=0,img_size[1]-1 do begin
                ; Get the smooth, overall trend.
                imgs_bg0[ii,jj] = min(imgs[*,ii,jj], nan=1)
            endfor
        endfor
        for ii=0,ntime-1 do imgs_bg[ii,*,*] = imgs_bg0
    endif else begin
        
        ; This background is a lower estimate.
        section_times = make_bins([0,ntime-1], width1, inner=1)
        nsection = n_elements(section_times)-1
        times = dindgen(ntime)
        
        imgs_bg1 = fltarr([ntime,img_size])
        for ii=0,img_size[0]-1 do begin
            for jj=0,img_size[1]-1 do begin
                cnt_raw = imgs[*,ii,jj]
                xxs = fltarr(nsection)
                yys = fltarr(nsection)
                
                for kk=0,nsection-1 do begin
                    yys[kk] = min(cnt_raw[section_times[kk]:section_times[kk+1]-1], index)
                    xxs[kk] = width1*kk+index
                    xxs[kk] = width1*kk+width1*0.5
                endfor
                xxs = [0,xxs,ntime-1]
                yys = [yys[0],yys,yys[nsection-1]]
                imgs_bg1[*,ii,jj] = smooth(interpol(yys, xxs, times),width1, edge_mirror=1)
                imgs_cal = cnt_raw-imgs_bg1[*,ii,jj]
                offset = min(imgs_cal)
                imgs_bg1[*,ii,jj] += offset
            endfor
        endfor
;if keyword_set(window) then return, imgs_bg1
        
        ; This background is an upper limits.
        imgs_bg2 = fltarr([ntime,img_size])
        for ii=0,img_size[0]-1 do begin
            for jj=0,img_size[1]-1 do begin
                cnt_raw = imgs[*,ii,jj]
                ; Get the moving average at a small window.
                imgs_bg2[*,ii,jj] = smooth(cnt_raw,width2,nan=1,edge_mirror=1)
                ; Offset the moving average by the local noise level.
                imgs_cal = cnt_raw-imgs_bg2[*,ii,jj]
                imgs_offset = smooth(abs(imgs_cal), width2, nan=1, edge_mirror=1)
                imgs_bg2[*,ii,jj] -= imgs_offset
            endfor
        endfor
        ; Make sure that the upper limit is always larger than the lower limit.
        index = where(imgs_bg2 lt imgs_bg1, count)
        if count ne 0 then imgs_bg2[index] = imgs_bg1[index]
        for ii=0,img_size[0]-1 do begin
            for jj=0,img_size[1]-1 do begin
                imgs_bg2[*,ii,jj] = smooth(imgs_bg2[*,ii,jj],width2,nan=1,edge_mirror=1)
            endfor
        endfor
        
        ; Weight the upper and lower limits to get the ideal background.
        max_count = 65535
        max_count = 6e4     ; saturation count.
        ; slightly lower than the real saturation count (65535) to catch the edge of the moon.
        w2 = (imgs_bg2-imgs_bg1)/(max_count-imgs_bg1)<1
;        w2 = (imgs_bg2)/(max_count)<1
        index = where(imgs ge max_count, count)
        if count ne 0 then begin
            imgs_bg2[index] = imgs[index]
            w2[index] = 1
        endif
        w1 = 1-w2
        imgs_bg = w1*imgs_bg1+w2*imgs_bg2
    endelse
    
    return, imgs_bg

end


;function themis_asi_calc_bg_count, imgs, window=window
;
;    img_size = size(reform(imgs[0,*,*]),dimensions=1)
;    ntime = n_elements(imgs[*,0,0])
;
;    if n_elements(window) eq 0 then window = 900    ; sec.
;    time_step = 3   ; sec.
;    width = window/time_step
;
;    imgs_bg = fltarr([ntime,img_size])
;    index = where(imgs ge 65535, count)
;    if count ne 0 then imgs[index] = !values.f_nan
;
;    if ntime le width then begin
;        imgs_bg0 = fltarr(img_size)
;        for ii=0,img_size[0]-1 do begin
;            for jj=0,img_size[1]-1 do begin
;                ; Get the smooth, overall trend.
;                imgs_bg0[ii,jj] = min(imgs[*,ii,jj], nan=1)
;            endfor
;        endfor
;        for ii=0,ntime-1 do imgs_bg[ii,*,*] = imgs_bg0
;    endif else begin
;        for ii=0,img_size[0]-1 do begin
;            for jj=0,img_size[1]-1 do begin                
;                ; Get the smooth, overall trend.
;                imgs_bg[*,ii,jj] = smooth(imgs[*,ii,jj], width, nan=1, edge_mirror=1)
;;                ; Adjust for standard deviation, estimate using smooth+abs.
;;                imgs_cal = imgs[*,ii,jj]-imgs_bg[*,ii,jj]
;;                imgs_offset = smooth(abs(imgs_cal), width, nan=1, edge_mirror=1)
;;                imgs_bg[*,ii,jj] -= imgs_offset
;;                ; Do it again.
;;                imgs_cal = imgs[*,ii,jj]-imgs_bg[*,ii,jj]
;;                imgs_offset = smooth(abs(imgs_cal), width, nan=1, edge_mirror=1)
;;                imgs_bg[*,ii,jj] -= imgs_offset
;
;                ; Adjust for standard deviation, estimate using smooth+abs.
;                imgs_cal = imgs[*,ii,jj]-imgs_bg[*,ii,jj]
;                imgs_offset = smooth(imgs_cal<0, width, nan=1, edge_mirror=1)
;                imgs_bg[*,ii,jj] += imgs_offset*2
;;                ; Do it again.
;;                imgs_cal = imgs[*,ii,jj]-imgs_bg[*,ii,jj]
;;                imgs_offset = smooth(imgs_cal<0, width, nan=1, edge_mirror=1)
;;                imgs_bg[*,ii,jj] += imgs_offset
;                
;;                ; Ensure no negative value.
;;                imgs_cal = imgs[*,ii,jj]-imgs_bg[*,ii,jj]
;;                imgs_bg[*,ii,jj] += min(imgs_cal)
;;if n_elements(where(finite(imgs[*,ii,jj]))) ne 0 then stop
;            endfor
;        endfor
;    endelse
;
;
;
;    ;    stop
;    ;    for ii=0,img_size[0]-1 do begin
;    ;        for jj=0,img_size[1]-1 do begin
;    ;            print, ii, jj
;    ;            plot, imgs[*,ii,jj], yrange=[0,65535], ystyle=1
;    ;            wait, 0.02
;    ;        endfor
;    ;    endfor
;;    min_val = fltarr(ntime)
;;    min_val2 = fltarr(ntime)
;;    imgs_del = imgs-imgs_bg
;;    for ii=0,ntime-1 do begin
;;        min_val[ii] = min(imgs_del[ii,*,*],nan=1)
;;;        index = where(imgs_del lt 0)
;;;        min_val2[ii] = stddev(imgs_del[index],nan=1)
;;    endfor
;;
;;stop
;    return, imgs_bg
;
;    ;    imgs_bg_offset = fltarr(img_size)
;    ;    imgs_cal = imgs-imgs_bg
;    ;    for ii=0,img_size[0]-1 do begin
;    ;        for jj=0,img_size[1]-1 do begin
;    ;            del_bg = stddev(imgs_cal[*,ii,jj])
;    ;            imgs_bg_offset[ii,jj] = del_bg
;    ;        endfor
;    ;    endfor
;
;
;    ;   foreach ii, times do tv, bytscl(reform(new_imgs[ii,*,*]), min=-1e2, max=1e2)
;    foreach ii, times do tv, bytscl(imgs_cal1[ii,*,*])
;
;end
