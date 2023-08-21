
; Settings.
input_time_range = time_double(['2013-05-01','2013-05-01/03:00'])
probe = 'f18'

; Calculatee AACGM mlat, mlon, mlt
glat_vars_madrigal = dmsp_read_glat_vars_madrigal(input_time_range, probe=probe, geodetic=1)
glat = get_var_data(glat_vars_madrigal[0], times=times)
glon = get_var_data(glat_vars_madrigal[1])
alt = get_var_data(glat_vars_madrigal[2])

aacgmidl
aacgmidl_v2
;aacgm_v2_com, igrf_v2_com
; coefs_v2 is the coef to be interpolated.
; we want time and height.
; cnvcoord_v2 is a wrapper of aacgm_v2_convert
;   aacgm_v2_convertgeocoord is the main function, geodetic is converted to geocentric around L906 in aacgmlib_v2.
;   cint_v2 is the coef from altitude to the fourth power
; mltconvert_v2 is the main function to concert between mlt/mlon.


ntime = n_elements(times)
mlat = fltarr(ntime)
mlon = fltarr(ntime)
mlt = fltarr(ntime)
for ii=0,ntime-1 do begin
    info = fix(strsplit(time_string(times[ii],tformat='YYYY_MM_DD_hh_mm_ss'),'_',extract=1))
    yr = info[0]
    mo = info[1]
    dy = info[2]
    hr = info[3]
    mt = info[4]
    sc = info[5]
    e = AACGM_v2_SetDateTime(yr,mo,dy,hr,mt,sc)
    lat = glat[ii]
    lon = glon[ii]
    hgt = alt[ii]
    p = cnvcoord_v2(lat,lon,hgt)
    mlat[ii] = p[0]
    mlon[ii] = p[1]
    mlt[ii] = mlt_v2(p[1])
endfor

var = prefix+'mlat_aacgm_calc'
store_data, var, times, mlat
add_setting, var, smart=1, dictionary($
    'display_type', 'scalar', $
    'short_name', 'MLat', $
    'unit', 'deg' )
var = prefix+'mlon_aacgm_calc'
store_data, var, times, mlon
add_setting, var, smart=1, dictionary($
    'display_type', 'scalar', $
    'short_name', 'MLon', $
    'unit', 'deg' )
var = prefix+'mlt_aacgm_calc'
store_data, var, times, mlt
add_setting, var, smart=1, dictionary($
    'display_type', 'scalar', $
    'short_name', 'MLT', $
    'unit', 'h' )
end