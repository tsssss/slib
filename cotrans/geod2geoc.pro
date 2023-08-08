;+
; Convert geodetic altitude latitude to geocentric distance and latitude.
; Adopted from SDT geoc2geod.
;-
function geod2geoc, gd_alt, gd_lat, gc_lat

    biga = 6378.137d
    finverse = 298.257223563d
    ecc = sqrt(2/finverse-1/finverse^2)
    bigb = biga*(1-1/finverse)

    mean_re = 6378.1400             ; this is the current difference
    rad = constant('rad')
    deg = constant('deg')

    latrad = gd_lat*rad
;
    bign = biga/sqrt(1-ecc^2*sin(latrad)^2)
    bigp = (bign + gd_alt)*cos(latrad)
    bigz = (bign*(1-ecc^2) + gd_alt)*sin(latrad)

    gc_dis = sqrt(bigp^2+bigz^2)
    gc_lat = atan(bigz,bigp)*deg

    too_close = where(abs(abs(gd_lat)-90.d) lt .01d, count)
    if count gt 0 then begin
        gc_dis[too_close] = gd_alt[too_close] + bigb
    endif


    return, gc_dis

end



gc_lat = smkarthm(-180,180,0.1,'dx')
gc_dis = fltarr(n_elements(gc_lat))+7000
gd_alt = geoc2geod(gc_dis, gc_lat, gd_lat)
gc_dis_test = geod2geoc(gd_alt, gd_lat, gc_lat_test)
end