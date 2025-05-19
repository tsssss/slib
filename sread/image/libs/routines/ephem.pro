;%W% %G%
;
PRO ephem,jd,ut,gha,dec,eqtime

    ;INPUT: 
    ;jd  Julian day number
    ;ut  Universal Time in hours

    ;OUTPUT:
    ;gha     Greenwich hour angle, the angle between the Greenwich
    ;        meridian and the meridian containing the subsolar pt
    ;dec     solar declination, latitude of subsolar point
    ;eqtime  equation of time, longitudinal correction to mean sun
    ;        position

    ; REF:  Explanatory Supplement to the Astronomical Almanac
    ;       ISBN 0-935702-68-7
    ;       University Science Books
    ;       1992
    ;       pp. 484-485

    ;calculate number of centuries from J2000
    t = (jd + (ut/24.) - 2451545.0) / 36525.
; print, 'ephemwic: ', sfmepoch(stoepoch(jd + ut/24.,'jd'),'yyyy-mm-dd hh:mi:ss.msc')
; !!! Sheng Tian: above shows there is original t is 12 hour more.
    ;mean longitude corrected for aberration
    l = (280.460 + 36000.770 * t) MOD 360

    ;mean anomaly
    g = 357.528 + 35999.050 * t

    ;ecliptic longitude
    lm = l + 1.915 * SIN(g*!DTOR) + 0.020 * SIN(2*g*!DTOR)

     ;obliquity of the ecliptic
    ep = 23.4393 - 0.01300 * t


    ;equation of time
    eqtime = -1.915*SIN(g*!DTOR) - 0.020*SIN(2*g*!DTOR) $
            + 2.466*SIN(2*lm*!DTOR) - 0.053*SIN(4*lm*!DTOR)

    ;Greenwich hour angle
    gha = 15*ut - 180 + eqtime

    ;declination of sun
    dec = ASIN(SIN(ep*!DTOR) * SIN(lm*!DTOR)) * !RADEG

END

