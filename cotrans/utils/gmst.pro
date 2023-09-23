;+
; Return the GMST (Greenwich Mean Sidereal Time) at given time.
;
; time. UT sec in [n].
; gmst. An array in [n]. By default is in hour.
; degree. A boolean sets gsmt in degree.
; radian. A boolean sets gsmt in radian.
;
; Notes: See details (notation and variable names) in Hapgood 1992.
;   doi: 10.1016/0032-0633(92)90012-D.
;   Coefficients are from Almanac for computers 1990.
;-

function gmst, time, radian = radian, degree = degree

    secofday1 = 1/86400d
    mjd = secofday1*time+40587d
    mjd0 = floor(mjd)         ; modified julian date for date only.
    ut = (mjd-mjd0)*24        ; fraction of day, convert to hour.

    a = 6.69737456d
    b = 0.0657098243942505d   ; = 2400.051336D/36525d
    c = 1.002737909d
    d = 51544.5d              ; J2000.0 in modified julian day.

    gmst = (((a+b*(mjd0-d)+c*ut) mod 24)+24) mod 24   ; in hour.
    if keyword_set(degree) then gmst *= 15            ; in degree.
    if keyword_set(radian) then gmst *= (!dpi/12)     ; in radian.

    return, gmst
end
