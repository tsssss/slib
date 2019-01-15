;+
; Read Polar MLT image.
;-

pro polar_read_mltimg, utr0, height = height, minlat = minlat
    
    compile_opt idl2
    on_error, 0
    
    ; emission height and min geomagnetic latitude.
    if n_elements(height) eq 0 then height = 100d   ; km in altitude.
    if n_elements(minlat) eq 0 then minlat = 50d    ; degree.

    pre0 = 'po_'
    pre1 = 'po_uvi_'
    re1 = 1d/6378d
    deg = 180d/!dpi
    rad = !dpi/180d

;---Read level1 data, attitube, orbit and platform attitude.
    ; uvi data.
    polar_read_uvi, utr0, 'l1', errmsg=errmsg
    if errmsg ne 0 then return
    
    ; start and end times of a frame.
    rename_var, 'FILTER', to=pre1+'filter'
    get_data, 'FRAMERATE', ut1s, rate
    ut0s = ut1s-(rate+4)*9.2
    store_data, pre1+'frame', ut1s, ut0s
    var = pre1+'system'
    rename_var, 'SYSTEM', to=var
    sys_add, var, 1, to=var
    
    ; platform attitude.
    var = pre1+'dsp'
    vars = ['Epoch','DSP_ANGLE']
    polar_read_ssc, utr0, 'pa', errmsg=errmsg, variable=vars
    if errmsg ne 0 then return
    get_data, 'DSP_ANGLE', uts, dsp
    idx = where(abs(dsp) le 180, cnt)
    if cnt eq 0 then return
    ; spline interpolation introduces wigles around jumps.
    ; linear interpolation seems to perform better.
    ;dsp = spl_interp(uts[idx],dsp[idx],spl_init(uts[idx],dsp[idx]),ut0s)
    dsp = interpol(dsp[idx], uts[idx], ut0s)*deg
    store_data, var, ut0s, dsp
    
    ; orbit.
    vars = ['Epoch','GCI_POS']
    polar_read_ssc, utr0, 'or_def', errmsg=errmsg, variable=vars
    if errmsg ne 0 then polar_read_ssc, utr0, 'or_pre', errmsg=errmsg, variable=vars
    if errmsg ne 0 then return
    var = pre0+'r_gci'
    get_data, 'GCI_POS', uts, orbit
    orbit = sinterpol(orbit, uts, ut0s)
    store_data, var, ut0s, orbit
    
    ; attitude.
    vars = ['Epoch','GCI_R_ASCENSION','GCI_DECLINATION']
    polar_read_ssc, utr0, 'at_def', errmsg=errmsg
    if errmsg ne 0 then polar_read_ssc, utr0, 'at_pre', errmsg=errmsg
    if errmsg ne 0 then return
    get_data, 'GCI_R_ASCENSION', uts, ra
    ra = interpol(ra, uts, ut0s)
    get_data, 'GCI_DECLINATION', uts, dec
    dec = interpol(dec, uts, ut0s)
    att = [[cos(dec)*cos(ra)],[cos(dec)*sin(ra)],[sin(dec)]]
    store_data, pre1+'att', ut0s, att

    
    ; calculate glat/glon, from looking direction at frame time.
    nrec = n_elements(ut0s)
    if n_elements(imgsz) eq 0 then imgsz = fix(4*(90-minlat))+1
    mltimgs = fltarr(nrec,imgsz,imgsz)
    get_data, pre1+'filter', tmp, filters
    get_data, pre1+'system', tmp, systems
    get_data, pre0+'r_gci', tmp, orbits
    get_data, pre1+'att', tmp, atts
    get_data, pre1+'dsp', tmp, dsps
    get_data, 'INT_IMAGE', tmp, imgs
    for i=0, nrec-1 do begin
        filter = filters[i]
        system = systems[i]
        orbit = reform(orbits[i,*])
        att = reform(atts[i,*])
        dsp = dsps[i]
        fet = stoepoch(ut0s[i],'unix')

        polar_uvilook, orbit, att, dsp, filter, lookdir, system=system
        polar_ptg, fet, height, att, orbit, system, lookdir, glat, glon, /geodetic
        
        
        ; other info.
        sphere = orbit[2] gt 0
        
        ; get mlat/mlon. method 1: geotoapex.
        apexfile = sparentdir(srootdir())+'/support/mlatlon.1997a.xdr'
        geotoapex, glat, glon, apexfile, mlat, mlon
        get_local_time, fet, glat, glon, apexfile, glt, mlt
        
        ; read raw image.
        img = reform(imgs[i,*,*])
        ; do line-of-sight and dayglow correction.
        ; polar_uvi_corr, fet, orbit, system, glat, glon, img
        ; convert to MLT image.
        get_mlt_image, img, mlat, mlt, minlat, sphere, mltimg, ncell=imgsz-1

        mltimgs[i,*,*] = mltimg
    endfor
    
    store_data, pre0+'mltimg', ut0s, mltimgs, minlat

end



utr0 = time_double(['1997-05-01/20:22','1997-05-01/20:25'])
polar_read_mltimg, utr0
end
