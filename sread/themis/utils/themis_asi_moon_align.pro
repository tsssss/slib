;+
; Align ASI images to moon at the highest elevation.
;-

function themis_asi_moon_align, input_time_range, site=site, asf_var=asf_var, get_name=get_name, min_moon_elev=min_moon_elev

    if n_elements(asf_var) eq 0 then begin
        time_range = time_double(input_time_range)
        asf_var = themis_read_asf(time_range, site=site, get_name=1)
        if check_if_update(asf_var, time_range) then asf_var = themis_read_asf(time_range, site=site)
    endif else begin
        if n_elements(site) eq 0 then site = get_setting(asf_var, 'site')
        if n_elements(input_time_range) ne 2 then input_time_range = minmax(get_var_time(asf_var))
    endelse
    time_range = time_double(input_time_range)

    moon_align_var = asf_var+'_moon_align'
    if keyword_set(get_name) then return, moon_align_var
    
    if n_elements(min_moon_elev) eq 0 then min_moon_elev = 5d
    


    ; Load predict moon position.
    var_info = themis_asi_read_moon_pos(time_range, site=site, get_name=1)
    moon_elev_var = var_info['moon_elev']
    if check_if_update(moon_elev_var, time_range) then var_info = themis_asi_read_moon_pos(time_range, site=site)

    ; Get info to align moon.
    moon_elevs = get_var_data(moon_elev_var, times=times)
    max_moon_elev = max(moon_elevs, index)
    target_time = times[index]
    info = themis_asi_moon_align_read_info(time_range, site=site, target_time=target_time, min_moon_elev=min_moon_elev)
    rotation_angles = info['rotation_angles']
    rotation_center = info['rotation_center']


    ; Rotate ASF to align the moon.
    asf_images = get_var_data(asf_var, times=common_times, in=time_range, limits=lim)
    if n_elements(common_times) ne n_elements(times) then rotation_angles = interpol(rotation_angles, times, common_times)
    ma_images = asf_images
    foreach time, common_times, time_id do begin
        rotation_angle = rotation_angles[time_id]
        if finite(rotation_angle,nan=1) or rotation_angle eq 0 then continue
        asf_image_current = reform(asf_images[time_id,*,*])
        ma_images[time_id,*,*] = rot(asf_image_current, rotation_angle, 1, $
            rotation_center[0], rotation_center[1], pivot=1, missing=0, interp=1)
    endforeach

    store_data, moon_align_var, common_times, ma_images, limits=lim
    options, moon_align_var, 'rotation_center', rotation_center
    options, moon_align_var, 'rotation_angles', rotation_angles
    options, moon_align_var, 'target_time', target_time
    return, moon_align_var


end