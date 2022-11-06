;+
; Convert the raw count to normalized count.
; To replace themis_read_asi_treat_raw_count.
;-
;
pro themis_read_asi_normalize_count, old_var, to=new_var, overwrite=overwrite, window=window

    if n_elements(new_var) eq 0 then new_var = old_var+'_norm'
    if keyword_set(overwrite) then new_var = old_var
    if n_elements(window) eq 0 then window = 600d

    min_count = 3000d       ; the background count for the raw image.
    med_count = 4000d       ; the median value for the raw count of the raw image.
    get_data, old_var, times, imgs, limits=lims

;    ; Remove values out of range (moon).
;    index = where(imgs eq 65535, count)
;    if count ne 0 then imgs[index] = !values.f_nan

    ; Calc background.
    imgs_bg = themis_asi_calc_bg_count(imgs, window=window)
    

    ; Get the initial calibrated image.
    imgs_cal = imgs-imgs_bg

    ; Normalize to a commen median.
    target_median = 60d
    typical_median = 1000d
;    typical_median = median(imgs_cal)
    coef = target_median/typical_median
    imgs_cal *= coef
    store_data, new_var, times, imgs_cal, limits=lims

    foreach time, times, ii do tv, bytscl(reform(imgs_cal[ii,*,*]), min=0, max=300)
stop
end


time_range = time_double(['2008-01-19/07:00','2008-01-19/08:00'])   ; moon, at 160,70 at t=0.
site = 'inuv'

time_range = time_double(['2008-01-17/03:00','2008-01-17/04:00'])   ; moon, at 40,140
site = 'kuuj'

time_range = time_double(['2008-02-13/02:00','2008-02-13/03:00'])
site = 'gill'

;time_range = time_double(['2007-09-23/09:00','2007-09-23/10:00'])
;site = 'gill'
;
;time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])   ; stable arc at 160,70
;site = 'gako'

themis_read_asf, time_range, site=site
get_data, 'thg_'+site+'_asf', times, imgs
themis_read_asi_normalize_count, 'thg_'+site+'_asf', window=120
end
