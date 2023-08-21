;+
; Convert r_geo (geocentric, in Re) to r_aacgm.
; Note: only mlat and mlon are obtained. dis is just 1.
;-

function geo2aacgm, r_geo, times, glat=glat, glon=glon, dis=dis

    aacgm_coef_var = aacgm_read_coef()
    coef_v2 = (get_var_data(aacgm_coef_var, times=coef_times))['geo2aacgm']
    ; dims are [time,kmax,ncoord,nquat]
    coef_v2 = sinterpol(coef_v2, coef_times, times)
    dims = size(coef_v2, dimensions=1)
    ntime = dims[0]
    kmax = dims[1]
    ncoord = dims[2]
    nquart = dims[2]

    re = constant('re')
    deg = constant('deg')
    rad = constant('rad')
    if n_elements(dis) ne ntime then dis = snorm(r_geo)
    if n_elements(glat) ne ntime then glat = asin(r_geo[*,2]/dis)*deg
    if n_elements(glon) ne ntime then glon = atan(r_geo[*,1],r_geo[*,0])*deg

    alts = (dis-1)*re
    alt_var = alts/2000.0   ; [ncoord]
    alt_var = alt_var # (dblarr(kmax*ncoord)+1) ; [ntime,kmax*ncoord]

    nquart = n_elements(coef_v2[0,0,0,*])
    coef_v2 = reform(coef_v2,[ntime,kmax*ncoord,nquart])
    ;cint_v2 = dblarr([ntime,kmax*ncoord])
    ;for ii=0,nquart-1 do cint_v2 += coef_v2[*,*,ii]*alt_var^ii
    cint_v2 = coef_v2[*,*,nquart-1]   ; [ntime,kmax,ncoord]
    for ii=nquart-2,0,-1 do begin
        cint_v2 = cint_v2*alt_var+coef_v2[*,*,ii]
    endfor
    cint_v2 = reform(cint_v2,[ntime,kmax,ncoord])
    coef_v2 = reform(coef_v2,[ntime,kmax,ncoord,nquart])

    

    order = sqrt(kmax)-1
    ylmval = aacgm_calc_rylm(glat,glon,order=order, degree=1) ; [ntime,kmax]

    
    r_aacgm = dblarr(ntime,ncoord)
    for ii=0,ncoord-1 do r_aacgm[*,ii] = total(ylmval*cint_v2[*,*,ii],2)

    
    
    fac = total(r_aacgm[*,0:1]^2,2)
    index = where(fac gt 1, count)
    if count ne 0 then r_aacgm[index,*] = !values.f_nan
    z_sign = r_aacgm[*,2]/abs(r_aacgm[*,2])
    r_aacgm[*,2] = sqrt(1-fac)*z_sign

    
;    mlat = asin(r_aacgm[*,2])*deg
;    mlon = atan(r_aacgm[*,1],r_aacgm[*,0])*deg
;    dis = snorm(r_aacgm)
    
    return, r_aacgm
    

;    fac = x*x + y*y
;    if fac gt 1. then begin
;      ; we are in the forbidden region and the solution is undefined
;      lat_out = !values.f_nan
;      lon_out = !values.f_nan
;      error = -64
;      return
;    endif
;
;    ztmp = sqrt(1. - fac)
;    if z lt 0 then z = -ztmp else z = ztmp
;
;    colat_temp = acos(z)
;    
;    if ((abs(x) lt 1e-8) and (abs(y) lt 1e-8)) then $
;        lon_temp = 0 $
;    else $
;        lon_temp = atan(y,x)
;
;    lon_output = lon_temp
;
;    lat_out = 90. - colat_output/DTOR ;*180.0/!pi
;    lon_out = lon_output/DTOR ;*180.0/!pi


end

time_range = time_double(['2013-05-01','2013-05-01/03:00'])
probe = 'f18'
mlat_vars = dmsp_read_mlat_vars_cdaweb(time_range, probe=probe)
glat_vars = dmsp_read_glat_vars_madrigal(time_range, probe=probe)
mlat_vars2 = dmsp_read_mlat_vars_madrigal(time_range, probe=probe)
;r_var = dmsp_read_orbit(time_range, probe=probe, coord='geo')
;r_geo = get_var_data(r_var, times=times)
;r_aacgm = geo2aacgm(r_geo, times)
stop



rad = constant('rad')
glat = 50.
glon = 120.
alt = 111.
year = 1997
month = 6
day = 25


glat = -30.80
glon = 116.16
alt = 848.46
year = 2013
month = 5
day = 1


;aacgmidl
;aacgmidl_v2
;aacgmlib_v2
;ret = aacgm_v2_setdatetime(year,month,day)
;p1 = cnvcoord_v2(glat,glon,alt, gcentric=1)
;;mlt = mlt_v2(p1[1])
;print, 'mlat,mlon,alt,mlt'
;print, reform(p1), mlt

re = constant('re')
rad = constant('rad')
r_geos = [$
    [cos(glat*rad)*cos(glon*rad)*(1+alt/re)], $
    [cos(glat*rad)*sin(glon*rad)*(1+alt/re)], $
    [sin(glat*rad)*(1+alt/re)]]
times = time_double(string(year,format='(I04)')+string(month,format='(I02)')+string(day,format='(I02)'),tformat='YYYYMMDD')
r_aacgm = geo2aacgm(r_geos, times)
r_geo = aacgm2geo(r_aacgm, times)
end