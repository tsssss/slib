;+
; Convert the raw count to normalized count.
;-
;

pro themis_read_asi_treat_raw_count, old_var, to=new_var, on_the_fly=on_the_fly, overwrite=overwrite

    if n_elements(new_var) eq 0 then new_var = old_var+'_norm'
    if keyword_set(overwrite) then new_var = old_var

    min_count = 3000d       ; the background count for the raw image.
    med_count = 4000d       ; the median value for the raw count of the raw image.
    get_data, old_var, times, imgs, limits=lims

    if keyword_set(on_the_fly) then begin
        ntime = n_elements(times)
        min_counts = fltarr(ntime)
        med_counts = fltarr(ntime)
        for ii=0, ntime-1 do begin
            timg = reform(imgs[ii,*,*])
            index = where(timg ne 0, count)
            tdat = timg[index]
            if count eq 0 then continue
            min_counts[ii] = min(tdat)
            med_counts[ii] = median(tdat)
        endfor
        if ntime eq 1 then begin
            min_count = min_counts[0]
            med_count = med_counts[0]
        endif else begin
            min_count = median(min_counts)
            med_count = median(med_counts)
        endelse
    endif

    med_value = 60d     ; the median value for the count of the normalized image.
    scale_factor = med_value/(med_count-min_count)
    imgs = (imgs-min_count)>0
    imgs *= scale_factor
    store_data, new_var, times, imgs, limits=lims

end
