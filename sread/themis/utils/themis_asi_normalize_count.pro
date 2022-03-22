;+
; Calibrate raw count for asf or ast images.
; This calibration is designed to work with data longer or equal to 1 hour.
; It works for shorter time range but I wouldn't recommend to do so.
; 
; asi_var. A string for the input tplot_var.
; newname=. A string for the output tplot_var.
; window=. A number in sec to set smoothing window for background calculation.
;
; To replace themis_read_asi_normalize_count
;-
pro themis_asi_normalize_count, asi_var, newname=cal_var, window=window

    if n_elements(cal_var) eq 0 then cal_var = asi_var+'_norm'

    get_data, asi_var, times, imgs, limits=lims
    imgs_bg = themis_asi_calc_bg_count(imgs, window=window)

    ; imgs_cal is typicall from 100 to 20,000.
    imgs_cal = (imgs-imgs_bg)>0
    coef = 0.1    ; normalize the count to about 1 to 200.
    imgs_cal *= coef

    store_data, cal_var, times, imgs_cal, limits=lims

end
