;+
; Convert geocentric distance and latitude to geodetic altitude and latitude.
; Adopted from SDT geoc2geod.
;-
function geoc2geod, gc_dis, gc_lat, gd_lat, _extra=ex

    biga = 6378.137d
    finverse = 298.257223563d
    ecc = sqrt(2/finverse-1/finverse^2)
    bigb = biga*(1-1/finverse)

    mean_re = 6378.1400             ; this is the current difference
    rad = constant('rad')
    deg = constant('deg')

    latrad = gc_lat*rad

    bigz = gc_dis * sin(latrad)
    bigp = gc_dis * cos(latrad)
    ep2 = (biga^2-bigb^2)/bigb^2

    t2 = atan(bigz*biga,bigp*bigb)
    phi = atan(bigz+ep2*bigb*sin(t2)^3,bigp-ecc^2*biga*cos(t2)^3)
    gd_lat = phi*deg
    
    bign = biga/sqrt(1-(ecc*sin(phi))^2)
    gd_alt = bigp/cos(phi) - bign
    
    too_close = where(abs(abs(gc_lat)-90.d) lt .01d, count)
    if count gt 0 then begin
        gd_alt[too_close] = gc_dis[too_close] - bigb
    endif

    return, gd_alt

end