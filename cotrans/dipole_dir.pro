;+
; Return the dipole direction (unit vector) in GEO, work within 1900 to 2015.
;
; times. An array of UT sec in [n].
; v1, v2, v3. The components of the dipole direction in GEO.
; radian. A boolean sets v1/v2 as lat/lon in rad.
; degree. A boolean sets v1/v2 as lat/lon in deg.
;
; In Hapgood 1992, there are two ways to calculate the dipole GEO
; latitude and longitude: (a) interpolate from IGRF model coefficients
; (g01, g11, h11); (b) estimate from, e.g., the two equation below
; equation (9).
;
; Method (b) is used in this program. According to test_dipole_dir.pro,
; (a)'s error is < 0.01 deg, or 2e-4 rad,
; (b)'s error is < ~0.3 deg, or 5e-3 rad.
; The accuray of (b) is good enough.
;
; Method (a) use igrf11coeffs.txt at
; http://www.ngdc.noaa.gov/IAGA/vmod/igrf.html, which lists semi-
; normalized spherical harmonics coefficient. Only n=1 harmonics (g01, g11,
; and h11) are used, they are the beginning coefficients, thus no Schidt
; normalization is needed.
;-

pro dipole_dir, time, v1, v2, v3, degree=degree, radian=radian

    secofday1 = 1/86400d
    mjd = secofday1*time+40587d

    t0 = mjd - 46066d
    v1 = 1.3753194505715316d + 0.0000020466107099d*t0    ; in radian.
    v2 = 5.0457468675156072d - 0.0000006751951087d*t0    ; in radian.

    if keyword_set(radian) then return
    if keyword_set(degree) then begin
        deg = 180d/!dpi
        v1 *= deg
        v2 *= deg
        return
    endif
    
    t = 0.5*!dpi - v1
    p = v2
    v1 = sin(t)*cos(p)
    v2 = sin(t)*sin(p)
    v3 = cos(t)



end

time = sfmepoch(epoch,'unix')
dipole_dir, time, v1,v2,v3
print, v1,v2,v3
print, gmst(time)
rgsm = [v1,v2,v3]
rsm = gsm2sm(rgsm, time)
print, rsm

; test against a previous version.
epoch = stoepoch('2013-06-07/04:53:23')
sdipoledir, epoch, v1,v2,v3
print, v1,v2,v3
sgmst, epoch, gmst
print, gmst
rgsm = [v1,v2,v3]
rsm = sgsm2sm(rgsm, epoch)
print, rsm
end
