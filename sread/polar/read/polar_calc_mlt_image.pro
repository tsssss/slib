;+
; Calculate MLT image.
;-

pro polar_calc_mlt_image, input_time_range, emission_height=emission_height

;---Settings and inputs.
    half_size = 80d
    mlt_image_info = mlt_image_info(half_size)
    mlat_range = mlt_image_info.mlat_range
    min_mlat = mlat_range[0]
    max_mlat = mlat_range[1]
    if n_elements(emission_height) eq 0 then emission_height = 120d ; km in altitude.
    time_range = time_double(input_time_range)

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
    ntime = n_elements(ut0s)
    imgsz = mlt_image_info.image_size[0]
    mlt_images = fltarr(ntime,imgsz,imgsz)
    get_data, pre1+'filter', tmp, filters
    get_data, pre1+'system', tmp, systems
    get_data, pre0+'r_gci', tmp, orbits
    get_data, pre1+'att', tmp, atts
    get_data, pre1+'dsp', tmp, dsps
    get_data, 'INT_IMAGE', tmp, imgs
    ets = stoepoch(ut0s, 'unix')
    for i=0, ntime-1 do begin
        filter = filters[i]
        system = systems[i]
        orbit = reform(orbits[i,*])
        att = reform(atts[i,*])
        dsp = dsps[i]
        fet = ets[i]

        polar_uvilook, orbit, att, dsp, filter, lookdir, system=system
        polar_ptg, fet, emission_height, att, orbit, system, lookdir, glat, glon, /geodetic


        ; other info.
        sphere = orbit[2] gt 0

        ; get mlat/mlon. method 1: geo2apex.
        apexfile = sparentdir(srootdir())+'/support/mlatlon.1997a.xdr'
        geo2apex, glat, glon, mlat, mlon
        get_local_time, fet, glat, glon, glt, mlt

        ; read raw image.
        img = reform(imgs[i,*,*])
        ; do line-of-sight and dayglow correction.
        ; polar_uvi_corr, fet, orbit, system, glat, glon, img
        ; convert to MLT image.
        get_mlt_image, img, mlat, mlt, min_mlat, sphere, mlt_image, mcell=imgsz

        mlt_images[i,*,*] = mlt_image
    endfor


;---Save to memory.
    settings = mlt_image_info
    settings['display_type'] = 'image'
    settings['unit'] = 'Count #'
    settings = settings.tostruct()
    store_data, pre0+'mlt_image', ut0s, mlt_images, limits=settings


end

time_range = ['2008-01-19/06:00','2008-01-19/09:00']
polar_calc_mlt_image, time_range
end