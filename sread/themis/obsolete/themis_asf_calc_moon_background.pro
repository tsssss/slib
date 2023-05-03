
function themis_asf_calc_moon_background, input_time_range, site=site, asf_var=asf_var, resolution=resolution


;---Handle input.
    if n_elements(asf_var) eq 0 then begin
        time_range = time_double(input_time_range)
        asf_var = themis_read_asf(time_range, site=site, get_name=1)
        if check_if_update(asf_var, time_range) then asf_var = themis_read_asf(time_range, site=site)
    endif else begin
        if n_elements(site) eq 0 then site = get_setting(asf_var, 'site')
        if n_elements(input_time_range) ne 2 then input_time_range = minmax(get_var_time(asf_var))
    endelse
    time_range = time_double(input_time_range)


;---Read original asf images.
    orig_images = get_var_data(asf_var, in=time_range, times=times, limits=lim)
    image_size = lim.image_size
    npixel = product(image_size)
    nframe = n_elements(times)
    time_step = times[1]-times[0]
    orig_images_1d = reform(orig_images,[nframe,npixel])


;---Separate the edge and center pixels.    
    deg = constant('deg')
    rad = constant('rad')
    pixel_elevs = lim.pixel_elev
    pixel_azims = lim.pixel_azim

    edge_indices = where(finite(pixel_elevs,nan=1) or pixel_elevs le 0, nedge_index, $
        complement=center_indices, ncomplement=ncenter_index)
    center_indices_2d = fltarr(ncenter_index,2)
    center_indices_2d[*,0] = center_indices mod image_size[0]
    center_indices_2d[*,1] = (center_indices-center_indices_2d[*,0])/image_size[0]


    var_info = themis_asi_read_moon_pos(time_range, site=site, get_name=1)
    moon_elev_var = var_info['moon_elev']
    moon_azim_var = var_info['moon_azim']
    if check_if_update(moon_elev_var, time_range) then var_info = themis_asi_read_moon_pos(time_range, site=site)


;---If moon exist, then we perform a pixel-wise correction.
    ma_var = themis_asi_moon_align(time_range, site=site, asf_var=asf_var1)
    ma_images = get_var_data(ma_var, limits=ma_lim)
    ma_images_1d = reform(ma_images, [nframe,npixel])

    target_time = ma_lim.target_time
    moon_elev = get_var_data(moon_elev_var, at=target_time)
    moon_azim = get_var_data(moon_azim_var, at=target_time)
    moon_r3d = themis_asi_elev_azim_to_r3d(moon_elev,moon_azim)
    pixel_r3d = themis_asi_elev_azim_to_r3d(pixel_elevs,pixel_azims)

    moon_angles = acos($
        pixel_r3d[*,*,0]*moon_r3d[0]+$
        pixel_r3d[*,*,1]*moon_r3d[1]+$
        pixel_r3d[*,*,2]*moon_r3d[2])*deg


    ma_bg = fltarr([nframe,npixel])
    max_moon_angle = 40d
    for ii=0,npixel-1 do begin
;        if moon_angles[ii] ge max_moon_angle then continue
        orig_data = ma_images_1d[*,ii]
        index = where(orig_data ge 1, count)
        if count eq 0 then continue
        data = alog10(orig_data[index])
        val = 10.^mean(data)
        width = 6e4/val
        ma_bg[index,ii] = 10.^calc_baseline_smooth(data, width)
    endfor
    ma_bg = reform(ma_bg,[nframe,image_size])


    ; Rotate back.
    rotation_angles = ma_lim.rotation_angles
    rotation_center = ma_lim.rotation_center
    ma_bg_images = orig_images
    foreach time, times, time_id do begin
        rotation_angle = rotation_angles[time_id]
        if finite(rotation_angle,nan=1) or rotation_angle eq 0 then continue
        asf_image_current = reform(ma_bg[time_id,*,*])
        the_image = rot(asf_image_current, -rotation_angle, 1, $
            rotation_center[0], rotation_center[1], pivot=1, missing=0, interp=1)
        index = where(the_image lt 10, count)
        if count ne 0 then the_image[index] = asf_image_current[index]
        ma_bg_images[time_id,*,*] = the_image
    endforeach

    stop
end


time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])   ; stable arc w/o moon.
time_range = time_double(['2016-10-13/08:00','2016-10-13/09:00'])   ; stable arc with moon.
site = 'gako'
tmp = themis_asf_calc_moon_background(time_range, site=site)
end