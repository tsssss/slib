;+
; Calculate Sun's longitude, declination, right ascension, euqation of time.
; Based on http://aa.usno.navy.mil/faq/docs/SunApprox.php.
; Adopted from ssunlon.pro
; 
; time. A number or an array of time in UT sec.
; slon. Output. Sun's longitude. If mag is set, slon is the magnetic longitude.
; dec,ra. Output. Sun's declination and right ascend.
; eqt. Output. Sun's equation of time.
; mag. A boolean. Set it to return slon as the magnetic longitude.
; degree. A boolean. Set it to convert all outputs to deg. They are in rad by default.
;-
;

pro sun_coord, time, slon, dec, ra, eqt, mag=mag, degree=degree

    secofday1 = 1/86400d
    day = time*secofday1
    ut = (day mod 1)*24
    
    d = day - 10957.500
    e = 0.4090877233749509d - 6.2831853d-9*d
    g = 6.2400582213628066d + 0.0172019699945780d*d
    q = 4.8949329668507771d + 0.0172027916955899d*d
    l = q + 0.0334230551756914d*sin(g) + 0.0003490658503989d*sin(2*g)
    
    ; declination and right ascend.
    dec = asin(sin(e)*sin(l))          ; in radian.
    ra = atan(cos(e)*sin(l),cos(l))    ; in radian. IMPORTANT! atan(y,x).
    
    ; solar longitude.
    eqt = q - ra                       ; in radian.
    slon = !dpi *(1 - ut/12d) - eqt    ; in radian, in geo.
    
    ; short version of geo to mag (gm).
    if keyword_set(mag) then begin
        vx0 = cos(dec)*cos(slon)
        vy0 = cos(dec)*sin(slon)
        vz0 = sin(dec)

        t0 = day - 5479d
        lat = 1.3753194505715316d + 0.0000020466107099d*t0    ; in radian.
        lon = 5.0457468675156072d - 0.0000006751951087d*t0    ; in radian.
        sinl = sin(lon)
        cosl = cos(lon)
        slon = atan(-sinl*vx0+cosl*vy0, sin(lat)*(cosl*vx0+sinl*vy0)-cos(lat)*vz0)
    endif
    
    if keyword_set(degree) then begin
        deg = 180d/!dpi
        slon = (slon*deg) mod 360
        dec *= deg
        ra *= deg
        eqt *= deg
    endif

end

time = time_double('2018-08-28/12:34')
sun_coord, time, v1,v2,v3,v4
print, v1, v2, v3, v4
ssunlon, stoepoch(time,'unix'), v1,v2,v3,v4
print, v1, v2, v3, v4
sun_coord, time, v1,v2,v3,v4, /mag
print, v1, v2, v3, v4
ssunlon, stoepoch(time,'unix'), v1,v2,v3,v4, /mag
print, v1, v2, v3, v4
end

