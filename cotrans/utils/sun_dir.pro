;+
; Calculate angles related to the Sun.
; Based on http://aa.usno.navy.mil/faq/docs/SunApprox.php.
; Adopted from ssundir.
; 
; time. A number or an array of time in UT sec.
; e. Output. Mean obliquity of the ecliptic.
; l. Output. Geocentric apparent ecliptic longitude.
; g. Output. Mean anomaly of the Sun.
; q. Output. Mean longitude of the Sun.
; degree. A boolean. Set it to convert outputs to degree. They are in radian by default.
;-
pro sun_dir, time, e, l, g, q, degree=degree

    secofday1 = 1/86400d
    day = time*secofday1
    ut = (day mod 1)*24
    
    d = day - 10957.500
    e = 0.4090877233749509d - 6.2831853d-9*d
    g = 6.2400582213628066d + 0.0172019699945780d*d
    q = 4.8949329668507771d + 0.0172027916955899d*d
    l = q + 0.0334230551756914d*sin(g) + 0.0003490658503989d*sin(2*g)

    if keyword_set(degree) then begin
        deg = 180d/!dpi
        e *= deg
        g *= deg
        q *= deg
        l *= deg
    endif
    
end

time = time_double('2018-08-28/12:34')
sun_dir, time, v1,v2,v3,v4
print, v1, v2, v3, v4
ssundir, stoepoch(time,'unix'), v1,v2,v3,v4
print, v1, v2, v3, v4
end