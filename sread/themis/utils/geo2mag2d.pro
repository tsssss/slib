;+
; Convert glon and glat to mlon and mlat at certain time.
; This is for when time is a number and glon/glat are arrays.
; 
; I know two methods: (a) using the IGRF dipole axis (b) using geo2apex.
; Based on my tests, start from the same glon/glat for a given asi site,
; (b) mlon/mlat is closer to the mlon/mlat of the asi site.
; 
; This is weird b/c (b) only holds for 1997 whereas (a) is time dependent.
; But for consistency with asi, it's more reasonable to use (b).
;
; glat=. GLat in deg.
; glon=. GLon in deg.
; mlat=. MLat in deg, output.
; mlon=. MLon in deg, output.
; time. The time of the request.
;-

pro geo2mag2d, time, glat=glat, glon=glon, mlat=mlat, mlon=mlon, use_apex=use_apex

    if keyword_set(use_apex) then begin
        geo2apex, glat, glon, mlat, mlon
        return
    endif


    if n_elements(time) eq 0 then time = systime(1)
    dims = size(glat,dimensions=1)

    rad = constant('rad')
    tglat = glat*rad
    tglon = glon*rad
    
    ; GEO components.
    vx0 = cos(tglon)*cos(tglat)
    vy0 = sin(tglon)*cos(tglat)
    vz0 = sin(tglat)
    
    ; get T5.
    dipole_dir, time[0], lat, lon, /radian
    sinp =  sin(lat)
    cosp = -cos(lat)
    sinl =  sin(lon)
    cosl =  cos(lon)

    ; vectorized, so should be faster than matrix ##.
    tmp =  cosl*vx0 + sinl*vy0
    vx1 =  sinp*tmp + cosp*vz0
    vy1 = -sinl*vx0 + cosl*vy0
    vz1 = -cosp*tmp + sinp*vz0
    
    deg = constant('deg')
    mlon = atan(vy1,vx1)*deg
    mlat = asin(vz1)*deg
    
end

time_range = time_double(['2008-01-19/06:00','2008-01-19/09:00'])
test_time = time_double('1997')

; J data.
j_var = themis_read_weygand_j(time_range, id='j_ver')
get_data, j_var, times, limits=lim
glon_bins = lim.glon_bins
glat_bins = lim.glat_bins
nglon_bin = n_elements(glon_bins)
nglat_bin = n_elements(glat_bins)

old_glat = glat_bins ## (fltarr(nglon_bin)+1)
old_glon = (fltarr(nglat_bin)+1) ## glon_bins

; ASF data.
site = 'talo'
asf_info = themis_read_asi_info(time_range, site=site, id='asf')
old_glon = asf_info.asf_glon
old_glat = asf_info.asf_glat
nan_index = where(finite(old_glon,nan=1))
pixel_mlon = asf_info.asf_mlon
pixel_mlat = asf_info.asf_mlat

geo2mag2d, test_time, glon=old_glon, glat=old_glat, mlon=old_mlon, mlat=old_mlat, use_apex=0
geo2mag2d, test_time, glon=old_glon, glat=old_glat, mlon=apex_mlon, mlat=apex_mlat, use_apex=1
apex_mlat[nan_index] = !values.f_nan
apex_mlon[nan_index] = !values.f_nan

sgopen, 0, xsize=9, ysize=3
poss = sgcalcpos(1,3,margins=[0,0,0,0])
nlevel = 80
contour, pixel_mlon, position=poss[*,0], iso=1, nlevel=nlevel, xstyle=1, ystyle=1, noerase=1, xtickformat='(A1)', ytickformat='(A1)'
contour, old_mlon, position=poss[*,1], iso=1, nlevel=nlevel, xstyle=1, ystyle=1, noerase=1, xtickformat='(A1)', ytickformat='(A1)'
contour, apex_mlon, position=poss[*,2], iso=1, nlevel=nlevel, xstyle=1, ystyle=1, noerase=1, xtickformat='(A1)', ytickformat='(A1)'

contour, pixel_mlat, position=poss[*,0], iso=1, nlevel=nlevel, xstyle=1, ystyle=1, noerase=1, xtickformat='(A1)', ytickformat='(A1)'
contour, old_mlat, position=poss[*,1], iso=1, nlevel=nlevel, xstyle=1, ystyle=1, noerase=1, xtickformat='(A1)', ytickformat='(A1)'
contour, apex_mlat, position=poss[*,2], iso=1, nlevel=nlevel, xstyle=1, ystyle=1, noerase=1, xtickformat='(A1)', ytickformat='(A1)'
end