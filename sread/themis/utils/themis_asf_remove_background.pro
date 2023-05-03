;+
; Calculate the general background for a series of given asf_images.
;-

function moon_angle_to_weight, xxs

    return, (tanh((60-xxs)/30)+1)*0.5

end


function value_to_weight, xxs

    ;return, (tanh((xxs-2e4)/1e4)+1)
    return, exp(xxs/1e4)

end



function themis_asf_remove_background, input_time_range, site=site, asf_var=asf_var

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
    if n_elements(newname) eq 0 then newname = asf_var+'_norm'
    get_data, asf_var, times, orig_images, limits=lim
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

    
    
;---Temporal background.
    min_sky_elev = 20d
    sky_pixels = where(pixel_elevs ge min_sky_elev, count)
    if count eq 0 then message, 'Inconsistency ...'

    ; Consider the moon.
    min_moon_angle = 40d
    var_info = themis_asi_read_moon_pos(time_range, site=site, get_name=1)
    moon_elev_var = var_info['moon_elev']
    moon_azim_var = var_info['moon_azim']
    if check_if_update(moon_elev_var, time_range) then var_info = themis_asi_read_moon_pos(time_range, site=site)
    moon_elevs = get_var_data(moon_elev_var, at=times)

    bg0 = fltarr(nframe)
    pixel_r3d = themis_asi_elev_azim_to_r3d(pixel_elevs,pixel_azims)
    moon_angles_2d = fltarr([nframe,image_size])
    for ii=0,nframe-1 do begin
        tmp = orig_images_1d[ii,sky_pixels]
        if moon_elevs[ii] ge 0 then begin
            moon_elev = get_var_data(moon_elev_var, at=times[ii])
            moon_azim = get_var_data(moon_azim_var, at=times[ii])
            moon_r3d = themis_asi_elev_azim_to_r3d(moon_elev,moon_azim)
            moon_angles_2d[ii,*,*] = acos($
                pixel_r3d[*,*,0]*moon_r3d[0]+$
                pixel_r3d[*,*,1]*moon_r3d[1]+$
                pixel_r3d[*,*,2]*moon_r3d[2])*deg

            the_moon_angles = reform(moon_angles_2d[ii,*,*])
            index = where(the_moon_angles[sky_pixels] ge min_moon_angle, count)
            if count eq 0 then message, 'Inconsistency ...'
            tmp = tmp[index]
        endif
        bg0[ii] = min(tmp)
    endfor
    
    asf_images = orig_images
    for ii=0,nframe-1 do asf_images[ii,*,*] -= bg0[ii]
    asf_images >= 0
    asf_var1 = asf_var+'_bg_removed'
    store_data, asf_var1, times, asf_images, limits=lim
    
    
    
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

; This version works, but not ideal.
    window0 = 300
    ma_bg = fltarr([nframe,npixel])
    max_moon_angle = 40d
    for ii=0,npixel-1 do begin
;        if moon_angles[ii] ge max_moon_angle then continue
        orig_data = ma_images_1d[*,ii]
        index = where(orig_data ge 1, count)
        if count eq 0 then continue
        data = alog10(orig_data)
        mean_val = (10.^median(data[index]))
        window = ((1-tanh((mean_val-3e4)/1e4))*0.5)*(window0-3)+3
        if count le window/time_step*4 then continue
;        if window le time_step*2 then stop
        sector_index = time_to_range(index,time_step=1)
        if n_elements(sector_index) gt 2 then continue   ; we want onely one sector.
        ma_bg[index,ii] = 10.^calc_baseline_smooth(data[index], window, times[index])
    endfor
    ma_bg = reform(ma_bg,[nframe,image_size])
    
    
;    ; The background for the moon-aligned images.
;    ; Following themis_asi_cal_brightness.
;    imgs_bg0 = 0d
;
;    width_slow = 60
;    window_slow = 300
;    ; in [n,m,m]
;    imgs_slow = ma_images
;    for index_id=0,ncenter_index-1 do begin
;        ii = center_indices_2d[index_id,0]
;        jj = center_indices_2d[index_id,1]
;        imgs_slow[*,ii,jj] = calc_baseline_smooth(imgs_slow[*,ii,jj], window_slow, times)>0
;    end
;
;    sample_windows = [1,width_slow,600]*3
;    nsample_window = n_elements(sample_windows)
;    moon_weight = exp((2.5-moon_angles)/2.5)*2+1 ; decays to 1. in [m,m].
;
;    max_count = 6e4     ; moon-aligned images have already been background subtracted by about 3e3.
;    norm_count = fltarr([nframe,image_size])
;    for ii=0,nframe-1 do norm_count[ii,*,*] = round(imgs_slow[ii,*,*]*moon_weight)<max_count
;    norm_windows = exp((max_count-norm_count+1e4)/1e4)*2+3
;
;    index = where(norm_windows ge sample_windows[1], count, complement=index2, ncomplement=count2)
;    ma_bg = fltarr([nframe,image_size])
;    if count ne 0 then begin
;        weights = (norm_windows[index]-sample_windows[1])/(sample_windows[2]-sample_windows[1])
;        ma_bg[index] = weights*imgs_bg0+(1-weights)*imgs_slow[index]
;    endif
;    if count2 ne 0 then begin
;        weights = (norm_windows[index2]-sample_windows[0])/(sample_windows[1]-sample_windows[0])
;        ma_bg[index2] = weights*imgs_slow[index2]+(1-weights)*ma_images[index2]
;    endif

    
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
    
    
    
    
    ; Now we merge asf_images and ma_images2
    ma_images2 = asf_images-ma_bg_images
    moon_weight = moon_angle_to_weight(moon_angles_2d)
    moon_weight = 0.2
    value_weight = value_to_weight(ma_bg_images)
    weight = moon_weight*value_weight<1
    asf_images2 = asf_images*(1-weight)+ma_images2*weight
    stop

    
    return, bg0


end


time_range = time_double(['2008-01-19/07:00','2008-01-19/08:00'])   ; moon and background fluctuations.
site = 'inuv'
test_time = '2008-01-19/07:04'
; moon center: 140,60
; moon reflection: 135,215
; moon edge: 130,70
; moon glow: 130,95

time_range = time_double(['2008-02-13/02:00','2008-02-13/03:00'])   ; Chu+2015.
site = 'gill'   ; gill, kuuj, snkq
test_time = '2008-02-13/02:44'

time_range = time_double(['2013-03-17/08:00','2013-03-17/09:00'])   ; garbrielse's example
site = 'gako'

time_range = time_double(['2015-01-07/11:00','2015-01-07/12:00'])   ; Random example
site = 'fsim'
time_range = time_double(['2015-01-07/09:00','2015-01-07/10:00'])   ; Random example
site = 'snkq'
time_range = time_double(['2015-03-07/06:00','2015-03-07/07:00'])   ; Random example
site = 'rank'
;time_range = time_double(['2015-03-27/08:00','2015-03-27/09:00'])   ; Random example
;site = 'fsim' ; fykn, fsim

;time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])   ; stable arc.
;site = 'gako'
;test_time = '2016-10-13/12:10'
;; image edge: 20,120
;; stable arc: 100,50


tmp = themis_asf_remove_background(time_range, site=site)
end