;+
; Return the moon's elevation at certain glon and glat. 
; 
; time. Unix time.
; glon. GLon in deg.
; glat. GLat in deg.
; azimuth=. Return azimuth.
; degree=. A boolean. Set if glon,glat are in degree and return elev and azimuth in degree.
; 
; to replace smoon.
;-

function moon_elev, time, glon0, glat0, azimuth=azm, degree=degree

    rad = constant('rad')
    deg = constant('deg')
        
    jd = convert_time(time, from='unix', to='jd')
    moonpos, jd, ra, dec, dis, radian=1;, moon_glon, moon_glat

    ; glat/glon.
    glat = glat0 & glon = glon0
    glat = glat*rad & glon = glon*rad

    ; hour angle tau in rad, eqn (3.8).
    gmst = gmst(time, radian=1)     ; gmst in rad.
    tau = gmst + glon - ra

;    ; from equatorial to horizontal coord.
;    equ = transpose(cv_coord(from_sphere = [tau,dec,1d], /to_rect, /double))
;    hor = equ & srotate, hor,-(!dpi*0.5-glat), 1
;    azm = atan(hor[1],hor[0])       ; azimuth
;    alt = asin(hor[2])              ; altitude in rad.
    
    ; convert from earth's center to the required location on earth's surface.
    re = constant('re')
    r_moon_sphere = transpose([[tau],[dec],[dis/re]])
    r_moon = transpose(cv_coord(from_sphere=r_moon_sphere, to_rect=1, double=1))
    r_ground = cv_coord(from_sphere=[glon,glat,1], to_rect=1, double=1)
    for ii=0,2 do r_moon[*,ii] -= r_ground[ii]
    equ = sunitvec(r_moon)
    hor = equ
    srotate, hor,-(!dpi*0.5-glat), 1
    azm = atan(hor[*,1],hor[*,0])+!dpi  ; azimuth
    alt = asin(hor[*,2])              ; altitude in rad.
    
    ; refraction, https://en.wikipedia.org/wiki/Atmospheric_refraction.
    index = where(alt*deg ge 0, count)
    if count ne 0 then begin
        r = 1.02/(tan(alt+10.3/(alt*deg+5.11))) ; in minutes of arc
        r = r/60*rad    ; from minutes of arc to rad.
        alt[index] -= r[index]
    endif

    if keyword_set(degree) then begin
        alt *= deg & azm *= deg
    end

    return, alt

stop
end

time = sfmdate('2015-07-01/12:50 CDT', '%Y-%m-%d/%H:%M:%S %Z')
time = sfmdate('1991-05-19/13:00', '%Y-%m-%d/%H:%M:%S')
glat = 50
glon = 10
print, moon_elev(time, glon, glat, degree=1)
end
