function aacgm_mlon2mlt, mlon0, time, radian=radian, errmsg=errmsg

    retval = !null

    if n_elements(mlon0) eq 0 then begin
        errmsg = handle_error('No input mlon ...')
        return, retval
    endif
    
    mlon = mlon0
    deg = 180d/!dpi
    rad2hour = 12d/!dpi
    deg2hour = 12d/180
    mlon = (keyword_set(radian))? mlon*rad2hour: mlon*deg2hour
    
    sun_coord, time, slon, dec  ; in radian
    ntime = n_elements(time)
    dis = fltarr(ntime)+700d/constant('re')+1 ; a magic number from mlt_v02 ...
    ndim = 3
    r_geo = fltarr(ntime,ndim)
    r_geo[*,0] = dis*cos(dec)*cos(slon)
    r_geo[*,1] = dis*cos(dec)*sin(slon)
    r_geo[*,2] = dis*sin(dec)
    r_aacgm = geo2aacgm(r_geo, time)
    sun_mlon = r_get_lon(r_aacgm)*rad2hour

    
    lct = (mlon-sun_mlon+12) mod 24     ; in [0,24].
    index = where(lct gt 12, count)
    if count gt 0 then lct[index] -= 24 ; in [-12,12].
    
    return, lct

end


time_range = time_double(['2015-03-12/08:30','2015-03-12/10:30'])
probe = 'f19'
;time_range = ['2013-05-01','2013-05-03']
;probe = 'f18'
r1_var = dmsp_read_mlat_vars_madrigal(time_range, probe=probe)
;r2_var = dmsp_read_mlat_vars_cdaweb(time_range, probe=probe)
mlt = get_var_data(r1_var[1])
mlon = get_var_data(r1_var[2], times=times)
mlt2 = aacgm_mlon2mlt(mlon, times)

end