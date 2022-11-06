;+
; Return the MLon in deg, converted from MLT in hour.
; MLon by default is in [-180,180] deg.
;
; mlt. An array of any dimension, MLT in hour.
; radian. A boolean. Set if mlon is in raidan.
; time. A time in unix time in sec.
;-

function mlt2mlon, mlt0, time, radian=radian, errmsg=errmsg

    retval = !null
    
    if n_elements(mlt0) eq 0 then begin
        errmsg = handle_error('No input mlt ...')
        return, retval
    endif
    
    lct = mlt0  ; in hour.
    deg = 180d/!dpi
    rad2hour = 12/!dpi
    hour2deg = 180d/12
    
    sun_coord, time, slon, mag=1    ; slon in radian.
    slon *= rad2hour

    mlon = (lct-12+slon)*hour2deg
    index = where(mlon gt 180, count)
    if count gt 0 then mlon[index] -= 360 ; in [-180,180].
    
    if keyword_set(radian) then mlon = mlon*rad
    return, mlon

end

time_range = time_double(['2008-01-19/06:00','2008-01-19/07:00'])
times = make_bins(time_range,60)
mlt = 0
mlons = mlt2mlon(mlt, times)
end