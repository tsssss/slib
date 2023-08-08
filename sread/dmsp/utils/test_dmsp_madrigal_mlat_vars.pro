;+
; CDAWeb mlat_vars are accurate based on the correspondance between e- en spec and aurora.
; Now why madrigal mlat_vars are different?
; 
; 1. Madrigal data are 1-min resolution but inteprolated to 1 sec.
; 2. Madrigal derived data (e.g. mlon) have spikes due to the interpolation.
; 3. The mlat/mlt at SC location does not work.
; 4. Madrigal geodetic lat/lon/mlt can be successfully converted to the cdaweb aacgm mlat/mlon/mlt.
;    However: Madrigal data have spikes due to #1.
;-

probe = 'f18'
input_time_range = ['2013-05-01','2013-05-01/03:00']

prefix = 'dmsp'+probe+'_'



mlat_vars_cdaweb = dmsp_read_mlat_vars_cdaweb(input_time_range, probe=probe)
mlat_vars_madrigal = dmsp_read_mlat_vars_madrigal(input_time_range, probe=probe)
orbit_var_cdaweb = dmsp_read_orbit_cdaweb(input_time_range, probe=probe)
orbit_var_madrigal = dmsp_read_orbit_madrigal(input_time_range, probe=probe)

; This part test B field total and B IGRF.





stop






; This part test consistency of glat,glon,alt among noaa,cdaweb,madrigal.
;glat_vars_noaa = dmsp_read_glat_vars_noaa(input_time_range, probe=probe)
;glat_vars_cdaweb = dmsp_read_glat_vars_cdaweb(input_time_range, probe=probe)
;glat_vars_madrigal = dmsp_read_glat_vars_madrigal(input_time_range, probe=probe)
;
;glat_combo_var = stplot_merge(prefix+'glat_'+['noaa','madrigal','cdaweb'], $
;    output=prefix+'glat_combo', $
;    ytitle='GLat (deg)', $
;    labels=['NOAA','Madrigal','CDAWeb'], $
;    colors=sgcolor(['red','green','blue']) )
;glon_combo_var = stplot_merge(prefix+'glon_'+['noaa','madrigal','cdaweb'], $
;    output=prefix+'glon_combo', $
;    ytitle='GLon (deg)', $
;    labels=['NOAA','Madrigal','CDAWeb'], $
;    colors=sgcolor(['red','green','blue']) )
;    
;alt_combo_var = stplot_merge(prefix+'alt_'+['noaa','madrigal','cdaweb'], $
;    output=prefix+'alt_combo', $
;    ytitle='Altitude (km)', $
;    labels=['NOAA','Madrigal','CDAWeb'], $
;    colors=sgcolor(['red','green','blue']) )
;    
;sgopen, 0, size=[6,4]
;vars = prefix+['glat','glon','alt']+'_combo'
;tplot, vars, trange=input_time_range
;stop




; This part test Madrigal glat/glon/alt can reproduce cdaweb mlat/mlon/mlt.
;; Calculatee AACGM mlat, mlon, mlt
;glat_vars_madrigal = dmsp_read_glat_vars_madrigal(input_time_range, probe=probe, geodetic=1)
;glat = get_var_data(glat_vars_madrigal[0], times=times)
;glon = get_var_data(glat_vars_madrigal[1])
;alt = get_var_data(glat_vars_madrigal[2])
;
;aacgmidl
;aacgmidl_v2
;ntime = n_elements(times)
;mlat = fltarr(ntime)
;mlon = fltarr(ntime)
;mlt = fltarr(ntime)
;for ii=0,ntime-1 do begin
;    info = fix(strsplit(time_string(times[ii],tformat='YYYY_MM_DD_hh_mm_ss'),'_',extract=1))
;    yr = info[0]
;    mo = info[1]
;    dy = info[2]
;    hr = info[3]
;    mt = info[4]
;    sc = info[5]
;    e = AACGM_v2_SetDateTime(yr,mo,dy,hr,mt,sc)
;    lat = glat[ii]
;    lon = glon[ii]
;    hgt = alt[ii]
;    p = cnvcoord_v2(lat,lon,hgt)
;    mlat[ii] = p[0]
;    mlon[ii] = p[1]
;    mlt[ii] = mlt_v2(p[1])
;endfor
;
;var = prefix+'mlat_aacgm_calc'
;store_data, var, times, mlat
;add_setting, var, smart=1, dictionary($
;    'display_type', 'scalar', $
;    'short_name', 'MLat', $
;    'unit', 'deg' )
;var = prefix+'mlon_aacgm_calc'
;store_data, var, times, mlon
;add_setting, var, smart=1, dictionary($
;    'display_type', 'scalar', $
;    'short_name', 'MLon', $
;    'unit', 'deg' )
;var = prefix+'mlt_aacgm_calc'
;store_data, var, times, mlt
;add_setting, var, smart=1, dictionary($
;    'display_type', 'scalar', $
;    'short_name', 'MLT', $
;    'unit', 'h' )
;
;vars = prefix+'mlat_'+['cdaweb','madrigal','aacgm_calc']
;var = prefix+'mlat_combo'
;mlat_combo_var = stplot_merge(vars, labels=['CDAWeb','Madrigal','AACGM Calc'], $
;    colors=constant('rgb'), output=var)
;vars = prefix+'mlon_'+['cdaweb','madrigal','aacgm_calc']
;var = prefix+'mlon_combo'
;mlon_combo_var = stplot_merge(vars, labels=['CDAWeb','Madrigal','AACGM Calc'], $
;    colors=constant('rgb'), output=var)
;vars = prefix+'mlat_'+['cdaweb','madrigal','aacgm_calc']
;var = prefix+'mlt_combo'
;mlt_combo_var = stplot_merge(vars, labels=['CDAWeb','Madrigal','AACGM Calc'], $
;    colors=constant('rgb'), output=var)
;sgopen, 0, size=[6,4]
;vars = prefix+['mlat','mlon','mlt']+'_combo'
;tplot, vars
;
;stop




; Calculate mlat using madrigal orbit.
deg = constant('deg')
r_mag_madrigal = dmsp_read_orbit_madrigal(input_time_range, probe=probe, coord='mag')
r_mag = get_var_data(r_mag_madrigal, times=times)
mlat = asin(r_mag[*,2]/snorm(r_mag))*deg
mlt = mlon2mlt(atan(r_mag[*,1],r_mag[*,0]), times, radian=1)
var = prefix+'mlat_calc'
store_data, var, times, mlat
add_setting, var, smart=1, dictionary($
    'display_type', 'scalar', $
    'short_name', 'MLat', $
    'unit', 'deg' )
var = prefix+'mlt_calc'
store_data, var, times, mlt
add_setting, var, smart=1, dictionary($
    'display_type', 'scalar', $
    'short_name', 'MLT', $
    'unit', 'deg' )

vars = prefix+'mlat_'+['calc','madrigal','cdaweb']
mlat_combo_var = stplot_merge(vars, $
    output=prefix+'mlat_combo', $
    ytitle='MLat (deg)', $
    labels=['Calc','Madrigal','CDAWeb'], $
    colors=constant('rgb'))
vars = prefix+'mlt_'+['calc','madrigal','cdaweb']
mlt_combo_var = stplot_merge(vars, $
    output=prefix+'mlt_combo', $
    ytitle='MLT (h)', $
    labels=['Calc','Madrigal','CDAWeb'], $
    colors=constant('rgb'))
stop



end