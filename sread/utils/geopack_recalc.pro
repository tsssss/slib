;+
; A function wrapper to the IDL geopack_recalc procedure.
; 
; time. A ut time.
; return. The tilt angle in radian.
;-
function geopack_recalc, time

    t_epoch = convert_time(time, from='unix', to='epoch')
    geopack_epoch, t_epoch, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
    geopack_recalc, yr, mo, dy, hr, mi, sc+msc*0.001d, /date, tilt=tilt
    
    return, tilt
end