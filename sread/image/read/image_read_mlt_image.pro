 ;+
; c.f. read_image_fuv.pro and polar_calc_mlt_image
;-

function image_read_mlt_image, input_time_range, emission_height=emission_height, $
    id=id, spin_phase=spin_phase, $
    errmsg=errmsg, get_name=get_name, update=update

    errmsg = ''
    retval = ''

    var_info = 'im_mlt_image'
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

;---Settings and inputs.
    half_size = 80d     ; full size 160 = 4*(90-50)
    mlt_image_info = mlt_image_info(half_size)
    mlat_range = mlt_image_info.mlat_range
    min_mlat = mlat_range[0]
    max_mlat = mlat_range[1]
    if n_elements(emission_height) eq 0 then emission_height = 130d ; km in altitude, from the original image routines.
    if n_elements(id) eq 0 then id = 'wic_k0'

    files = image_ld_fuv(time_range, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval
    image_lib_dir = image_get_lib_dir()


;---Prepare to read vars.
    var_list = list()

    time_var = 'EPOCH'

    if id eq 'wic_k0' then begin
        image_type = 'WIC'
    endif else begin
        image_type = 'SI'
    endelse
    image_var = strupcase(image_type+'_pixels')
    xyz = strupcase(constant('xyz'))
    in_vars = [image_var,'VFOV','HFOV','FOVSCALE',$
        'SV_'+xyz, $
        'SPINPHASE', $
        'ORB_'+xyz, $
        'SCSV_'+xyz, $
        'INSTRUMENT_ID' ]
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'time_var_name', time_var, $
        'time_var_type', 'Epoch' )

    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval


    raw_images = get_var_data(image_var, times=times)
    foreach time, times, tid do begin
        img = reform(raw_images[tid,*,*])
        if id eq 'wic_k0' then begin
            timg = float(reverse(rotate(img,1),2))
        endif else begin
            timg = float(rotate(img,3))
        endelse
        raw_images[tid,*,*] = timg
    endforeach
    image_size = mlt_image_info.image_size
    npx = n_elements(reform(raw_images[0,*,0]))
    ntime = n_elements(times)
    mlt_images = fltarr([ntime,image_size])
    all_instr = ['WIC','SI1356','SI1218']
    if n_elements(spin_phase) eq 0 then spin_phase = get_var_data('SPINPHASE')

    fov_scales = get_var_data('FOVSCALE')
    hfovs = get_var_data('HFOV')*fov_scales/npx
    vfovs = get_var_data('VFOV')*fov_scales/npx
    ets = stoepoch(times,'unix')

    foreach time, times, tid do begin
        instr = strtrim(get_var_data('INSTRUMENT_ID', at=time),2)
        yr = fix(stodate(time,'%Y'))
        doy = fix(stodate(time,'%j'))

        ; instrument azimuth, co elevation, and roll angle.
        instr_id = where(instr eq all_instr)
        image_get_inst_angles_p, instr_id, yr, doy, instr_angles, image_lib_dir
        azim = instr_angles[0]
        elev = instr_angles[1]
        roll = instr_angles[2]

        ; get pointing info, glat/glon.
        the_time = lonarr(2)
        the_time[0] = yr*1000L+doy
        the_time[1] = (time mod constant('secofday'))*1d3   ; the total milli sec of the day.

        sv = fltarr(3)
        foreach var, 'SV_'+xyz, vid do sv[vid] = get_var_data(var, at=time)

        orbit = fltarr(3)
        foreach var, 'ORB_'+xyz, vid do orbit[vid] = get_var_data(var, at=time)

        scsv = fltarr(3)
        foreach var, 'SCSV_'+xyz, vid do scsv[vid] = get_var_data(var, at=time)

        spinphase = spin_phase[tid]
        vfov = vfovs[tid]
        hfov = hfovs[tid]

        image_ptg, emission_height, sv, orbit, scsv, $
            spinphase, the_time, npx, npx, vfov, hfov, azim, elev, roll, $
            glat, glon  ; output
        glat[where(abs(glat) gt 1e20)] = !values.d_nan
        glon[where(abs(glon) gt 1e20)] = !values.d_nan
        
        ; other info.
        sphere = orbit[2] gt 0
        et = ets[tid]
            
        ; get mlat/mlon. method 1: geo2apex.
        raw_image = reform(raw_images[tid,*,*])
        geo2apex, glat, glon, mlat, mlon
        get_local_time, et, glat, glon, glt, mlt
        get_mlt_image, raw_image, mlat, mlt, min_mlat, sphere, mlt_image, mcell=image_size[0]
        mlt_images[tid,*,*] = mlt_image
    endforeach


;---Save to memory.
    settings = mlt_image_info
    settings['display_type'] = 'image'
    settings['unit'] = '#'
    settings['requested_time_range'] = time_range
    settings = settings.tostruct()
    store_data, var_info, times, mlt_images, limits=settings
    return, var_info

end

tr = ['2000-12-22/23:00','2000-12-22/23:30']
var = image_read_mlt_image(tr, id='wic_k0')
end