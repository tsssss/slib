;+
; Test to remove moon use the moon prediction.
;-

;---Settings.
    site = 'tpas'
    time_range = ['2016-01-28/06:00','2016-01-28/07:00']
    test_time = !null
    
    site = 'fsim'
    time_range = ['2013-03-17/06:00','2013-03-17/07:00']
    test_time = !null
    
;    site = 'rank'
;    time_range = ['2015-01-03/02:00','2015-01-03/03:00']
;    test_time = time_double('2015-01-03/02:15')

;    site = 'inuv'
;    time_range = ['2008-01-19/07:00','2008-01-19/08:00']
;    ;time_range = ['2008-01-19/12:00','2008-01-19/13:00']
;    test_time = !null

    time_range = time_double(['2008-01-19/07:00','2008-01-19/08:00'])   ; moon and background fluctuations.
    site = 'inuv'
    test_time = '2008-01-19/07:04'
    
    
;    time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])   ; stable arc.
;    site = 'gako'
;    test_time = '2016-10-13/12:10'
    
    
    time_range = time_double(time_range)

    asf_var = themis_read_asf(time_range, site=site, get_name=1)
    if check_if_update(asf_var, time_range) then asf_var = themis_read_asf(time_range, site=site)
    moon_vars = themis_asi_read_moon_pos(time_range, site=site)
    moon_elev_var = moon_vars['moon_elev']
    moon_azim_var = moon_vars['moon_azim']

    ; Load pixel info.
    site_info = themis_read_asi_info(time_range, site=site, id='asf')
    pixel_elevs = site_info['asf_elev']
    pixel_azims = site_info['asf_azim']


    asf_images = get_var_data(asf_var, times=times)
    the_times = [times[0],times[-1]]
    r2d_list = list()
    r3d_list = list()
    foreach time, the_times do begin
        moon_elev = get_var_data(moon_elev_var, at=time)
        moon_azim = get_var_data(moon_azim_var, at=time)
        r2d_list.add, [moon_elev,moon_azim]
        r3d_list.add, themis_asi_elev_azim_to_r3d(moon_elev, moon_azim)
    endforeach
    r3d_center = sunitvec(vec_cross(r3d_list[0], r3d_list[1]))
    r2d_center = themis_asi_r3d_to_elev_azim(r3d_center)
    center_elev = r2d_center[0]
    center_azim = r2d_center[1]
    rotation_center = themis_asi_elev_azim_to_xy(center_elev, center_azim, pixel_elevs, pixel_azims)
    rotation_start = themis_asi_elev_azim_to_xy((r2d_list[0])[0], (r2d_list[0])[1], pixel_elevs, pixel_azims)
    rotation_end = themis_asi_elev_azim_to_xy((r2d_list[1])[0], (r2d_list[1])[1], pixel_elevs, pixel_azims)
    r_start = rotation_start-rotation_center
    r_end = rotation_end-rotation_center
    rotation_angle = sang(r_start,r_end, deg=1)


;---Apply rotation info.
    time_index = lazy_where(times, '[]', the_times)
    orig_images = asf_images[time_index,*,*]
    rotation_angles = interpol([0,rotation_angle], the_times, times[time_index])
    aligned_images = orig_images
    foreach time_id, time_index, id do begin
        the_image = reform(asf_images[time_id,*,*])
        aligned_images[id,*,*] = rot(the_image, -rotation_angles[id], 1, $
            rotation_center[0], rotation_center[1], pivot=1, missing=1, interp=1, cubic=-0.5)
    endforeach

    aligned_image_bg = reform(asf_images[0,*,*])
    ntime = n_elements(time_index)
    for ii=0,255 do begin
        for jj=0,255 do begin
            tmp = aligned_images[*,ii,jj]
            index = where(tmp gt 0, count)
            if count eq 0 then continue
            tmp = tmp[index]
            tmp = tmp[sort(tmp)]
            aligned_image_bg[ii,jj] = tmp[ntime*0.2]
            ;aligned_image_bg[ii,jj] = median(tmp)
        endfor
    endfor
    
    
    orig_image_bg = reform(asf_images[0,*,*])
    ntime = n_elements(time_index)
    for ii=0,255 do begin
        for jj=0,255 do begin
            tmp = orig_images[*,ii,jj]
            tmp = tmp[sort(tmp)]
            orig_image_bg[ii,jj] = tmp[ntime*0.2]
        endfor
    endfor
    
    avg_counts = themis_asi_plot_raw_count_survey(aligned_images, times, test_time=test_time)
    
    time_step = 3d
    window = 300d
    width = window/time_step
    
    
    bg_images = aligned_images
    for ii=0,255 do begin
        for jj=0,255 do begin
            bg = smooth(bg_images[*,ii,jj], width, nan=1, edge_mirror=1)
            offset = smooth(abs(bg_images[*,ii,jj]-bg), width, nan=1, edge_mirror=1)
            bg_images[*,ii,jj] = bg-offset
        endfor
    endfor
    
    
    stddev_images = reform(aligned_images[0,*,*])
    for ii=0,255 do begin
        for jj=0,255 do begin
            tmp = aligned_images[*,ii,jj]
            index = where(tmp ne 0, count)
            if count eq 0 then continue
            stddev_images[ii,jj] = stddev(tmp)
        endfor
    endfor
stop




end
