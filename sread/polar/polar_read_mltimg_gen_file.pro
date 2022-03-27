;+
; Read Polar MLT image.
;-

pro polar_read_mlt_image_gen_file, time, $
    height=height, minlat=minlat, $
    filename=file, errmsg=errmsg, _extra=extra

    errmsg = ''

    if n_elements(file) eq 0 then begin
        errmsg = 'No output file ...'
        return
    endif

    if n_elements(time) eq 0 then begin
        errmsg = 'No input time ...'
        return
    endif
    secofday = constant('secofday')
    date = time[0]-(time[0] mod secofday)
    time_range = date+[0,secofday]

;test
;time_range = time_double(['2001-10-22/11:00','2001-10-22/11:05'])

    ; emission height and min geomagnetic latitude.
    if n_elements(height) eq 0 then height = 110d   ; km in altitude.
    if n_elements(minlat) eq 0 then minlat = 50d    ; degree.

    pre0 = 'po_'
    pre1 = 'po_uvi_'
    re = constant('re')
    re1 = 1d/re
    deg = constant('deg')
    rad = constant('rad')

;---Read level1 data, attitube, orbit and platform attitude.
    ; uvi data.
    polar_read_uvi, time_range, id='l1', errmsg=errmsg
    if errmsg ne '' then return

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
    vars = ['DSP_ANGLE']
    polar_read_ssc, time_range, id='pa', errmsg=errmsg, in_vars=vars
    if errmsg ne '' then return
    get_data, 'DSP_ANGLE', uts, dsp
    idx = where(abs(dsp) le 180, cnt)
    if cnt eq 0 then return
    ; spline interpolation introduces wigles around jumps.
    ; linear interpolation seems to perform better.
    ;dsp = spl_interp(uts[idx],dsp[idx],spl_init(uts[idx],dsp[idx]),ut0s)
    dsp = interpol(dsp[idx], uts[idx], ut0s)*deg
    store_data, var, ut0s, dsp

    ; orbit.
    vars = ['GCI_POS']
    polar_read_ssc, time_range, id='or_def', errmsg=errmsg, in_vars=vars
    if errmsg ne '' then polar_read_ssc, time_range, id='or_pre', errmsg=errmsg, in_vars=vars
    if errmsg ne '' then return
    var = pre0+'r_gci'
    get_data, 'GCI_POS', uts, orbit
    orbit = sinterpol(orbit, uts, ut0s)
    store_data, var, ut0s, orbit

    ; attitude.
    vars = ['GCI_R_ASCENSION','GCI_DECLINATION']
    polar_read_ssc, time_range, id='at_def', errmsg=errmsg, in_vars=vars
    if errmsg ne '' then polar_read_ssc, time_range, id='at_pre', errmsg=errmsg, in_vars=vars
    if errmsg ne '' then return
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
        get_mlt_image, img, mlat, mlt, minlat, sphere, mltimg, mcell=imgsz

        mltimgs[i,*,*] = mltimg
    endfor


    mltimg_size = [imgsz,imgsz]
    mlt_range = [-1,1]*12d
    maxlat = 90d
    mlat_range = [minlat,maxlat]
    ; Pixel x and y coord, in [0,1].
    xx_bins = (dblarr(imgsz)+1) ## smkarthm(0,1,imgsz,'n')
    yy_bins = transpose(xx_bins)
    ; Convert to [-1,1].
    xx_bins = xx_bins*2-1
    yy_bins = yy_bins*2-1
    rr_bins = sqrt(xx_bins^2+yy_bins^2)
    tt_bins = atan(yy_bins,xx_bins)     ; in [-pi,pi]
    ; Convert to mlat and mlt.
    ; in mlat_range.
    mlat_bin_centers = max(maxlat)-rr_bins*abs(maxlat-minlat);/max(rr_bins)
    ; in [-12,12], i.e., 0 at midnight. Need to shift by 90 deg.
    mlt_bin_centers = (tt_bins*constant('deg')+90)/15
    index = where(mlt_bin_centers lt -12, count)
    if count ne 0 then mlt_bin_centers[index] += 24
    index = where(mlt_bin_centers gt 12, count)
    if count ne 0 then mlt_bin_centers[index] -= 24


    store_data, pre0+'mltimg', ut0s, mltimgs, limits={$
        unit: '(#)', $  ; CCD pixel value.
        image_size: mltimg_size, $
        mlt_range: mlt_range, $
        mlat_range: mlat_range, $
        mlt_bins: mlt_bin_centers, $
        mlat_bins: mlat_bin_centers }


;---Save data to file.
    compress = 1
    ginfo = dictionary($
        'TITLE', 'Polar UVI images in MLT-MLat, converted to raw UVI images', $
        'TEXT', 'Generated by Sheng Tian at the University of Minnesota' )
    cdf_save_setting, ginfo, filename=file

    utname = 'ut_sec'
    cdf_save_var, utname, value=ut0s, filename=file
    settings = dictionary($
        'FIELDNAM', 'unix time', $
        'UNITS', 'sec', $
        'VAR_TYPE', 'support_data' )
    cdf_save_setting, settings, var=utname, filename=file

    mlt_var = 'mlt_bins'
    val = reform(transpose(mlt_bin_centers), [1,mltimg_size])
    val = mlt_bin_centers
    cdf_save_var, mlt_var, value=val, filename=file, save_as_one=1
    settings = dictionary($
        'FIELDNAM', 'pixel mlt', $
        'UNITS', 'h', $
        'VAR_TYPE', 'support_data')
    cdf_save_setting, settings, var=mlt_var, filename=file

    mlat_var = 'mlat_bins'
    val = reform(transpose(mlat_bin_centers), [1,mltimg_size])
    val = mlat_bin_centers
    cdf_save_var, mlat_var, value=val, filename=file, save_as_one=1
    settings = dictionary($
        'FIELDNAM', 'pixel mlat', $
        'UNITS', 'deg', $
        'VAR_TYPE', 'support_data')
    cdf_save_setting, settings, var=mlt_var, filename=file

    vname = 'mltimg'
    cdf_save_var, vname, value=mltimgs, filename=file
    settings = dictionary($
        'FIELDNAM', 'MLT image', $
        'image_size', mltimg_size, $
        'mlt_range', mlt_range, $
        'mlat_range', mlat_range, $
        'UNITS', '#', $
        'VAR_TYPE', 'data', $
        'DEPEND_0', utname, $
        'DEPEND_1', mlt_var, $
        'DEPEND_2', mlat_var )
    cdf_save_setting, settings, var=vname, filename=file

end



time_range = time_double(['2001-10-22/11:00','2001-10-22/11:05'])
file = join_path([homedir(),'test','test_polar_mltimg.cdf'])
file_delete, file, allow_nonexist=1
polar_read_mlt_image_gen_file, time_range, filename=file
end
