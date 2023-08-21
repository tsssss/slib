;+
; Return the MLT in hour, converted from mlon in deg.
; MLT is by default in [-12,12], which is good for studying nightside physics.
; 
; mlon. An array of any dimension. MLon in deg.
; radian. A boolean. Set if mlon is in radian.
; time. A time in unix time in sec.
; 
; The program works for either mlon is an array and time is a number,
; or mlon is a number and time is an array.
; 
; Adapted from slon2lt.
;-

function mlon2mlt, mlon0, time, radian=radian, errmsg=errmsg
    
    retval = !null
    
    if n_elements(mlon0) eq 0 then begin
        errmsg = handle_error('No input mlon ...')
        return, retval
    endif
    
    mlon = mlon0
    deg = 180d/!dpi
    rad2hour = 12d/!dpi
    deg2hour = 12d/180
    mlon = (keyword_set(radian))? mlon*rad2hour: mlon*deg2hour
    
    sun_coord, time, slon, mag=1     ; slon in radian.
    slon *= rad2hour
    
    lct = (mlon-slon+12) mod 24     ; in [0,24].
    index = where(lct gt 12, count)
    if count gt 0 then lct[index] -= 24 ; in [-12,12].
    
    return, lct

end