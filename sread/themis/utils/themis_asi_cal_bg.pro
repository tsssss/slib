;+
; Calibrate background count for a seires of asf images.
;
; To replace themis_asi_cal_brightness.
;-

function calc_baseline_smooth, asi_raw, window, times

    time_step = total(times[0:1]*[-1,1])
    width = window/time_step

    ; Get the smooth, overal trend.
    imgs_bg = smooth(asi_raw, width, nan=1, edge_mirror=1)

    ; Adjust for standar deviation, estimate using smooth+abs.
    imgs_cal = asi_raw-imgs_bg
    imgs_offset = smooth(abs(imgs_cal), width, nan=1, edge_mirror=1)

    imgs_bg -= imgs_offset

    return, imgs_bg

end


function themis_asi_cal_bg, input_time_range, site=site, asf_var=asf_var, newname=newname

    if n_elements(asf_var) eq 0 then begin
        time_range = time_double(input_time_range)
        asf_var = themis_read_asf(time_range, site=site, get_name=1)
        if check_if_update(asf_var, time_range) then asf_var = themis_read_asf(time_range, site=site)
    endif else begin
        if n_elements(site) eq 0 then site = get_setting(asf_var, 'site')
        if n_elements(input_time_range) ne 2 then input_time_range = minmax(get_var_time(asf_var))
    endelse
    time_range = time_double(input_time_range)
    
    
    
    if n_elements(newname) eq 0 then newname = asf_var+'_norm'
    get_data, asf_var, times, orig_images, limits=lim
    image_size = double(size(reform(orig_images[0,*,*]), dimensions=1))
    nframe = n_elements(times)
    time_step = times[1]-times[0]
    orig_images_1d = reform(orig_images,[nframe,product(image_size)])


    if n_elements(smooth_window) eq 0 then smooth_window = 2.5*60d  ; sec


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



;---Get the background level.
    bg_level = median(orig_images_1d[edge_indices])
    stop

;---A minimum background per frame.
    imgs_bg = fltarr([nframe])
    
    for ii=0,nframe-1 do begin
        imgs_bg[ii] = min(tmp[ii,center_indices])
    endfor
    window_slow = 600 ; 10 min.
    width_slow = window_slow/time_step
    imgs_bg = smooth(imgs_bg,width_slow, nan=1, edge_mirror=1)
    ;imgs_bg0 = float(orig_images)
    ;for ii=0,nframe-1 do imgs_bg0[ii,*,*] = imgs_bg[ii]
    
    
    imgs_bg0 = float(orig_images)
    for ii=0,image_size[0]-1 do begin
        for jj=0,image_size[1]-1 do begin
            data = imgs_bg0[*,ii,jj]
            imgs_bg0[*,ii,jj] = calc_baseline_smooth(data, window_slow, times)
        endfor
    endfor
    stop
    
    
;---If no moon, then done.
    var_info = themis_asi_read_moon_pos(time_range, site=site, get_name=1)
    moon_elev_var = var_info['moon_elev']
    moon_azim_var = var_info['moon_azim']
    if check_if_update(moon_elev_var, time_range) then var_info = themis_asi_read_moon_pos(time_range, site=site)
    moon_elevs = get_var_data(moon_elev_var, at=times)
    moon_azims = get_var_data(moon_azim_var, at=times)
    min_elev = 5
    index = where(moon_elevs ge min_elev, count)
    if count eq 0 then return, imgs_bg0


;---Collect info to align images to the moon.
    moon_align_var = themis_asi_moon_align(time_range, site=site, asf_var=asf_var, get_name=1)
    if check_if_update(moon_align_var, time_rangen) then moon_align_var = themis_asi_moon_align(time_range, site=site, asf_var=asf_var)

    
    ; A background per pixel.
    width_moon = 20d    ; 1 min.
    width_moon = 200d   ; 10 min.
    window_moon = 600d
    max_count = 65535
    ma_images = get_var_data(moon_align_var)<max_count
    ma_bg = ma_images
    for ii=0,image_size[0]-1 do begin
        for jj=0,image_size[1]-1 do begin
            data = ma_images[*,ii,jj]
            index1 = where(data ne 0, count, complement=index2)
            if count eq 0 then continue
;            ma_bg[index1,ii,jj] = smooth(data, width_moon, nan=1, edge_mirror=1)
            ma_bg[index1,ii,jj] = calc_baseline_smooth(data, window_moon, times)
        endfor
    endfor
    
    ; Calculate the moon's angle and each pixel.
    moon_angles = fltarr([nframe,product(image_size)])
    moon_r3ds = themis_asi_elev_azim_to_r3d(moon_elevs,moon_azims)
    foreach center_index, center_indices do begin
        pixel_elev = pixel_elevs[center_index]
        pixel_azim = pixel_azims[center_index]
        pixel_r3d = themis_asi_elev_azim_to_r3d(pixel_elev,pixel_azim)
        moon_angles[*,center_index] = acos(moon_r3ds # transpose(pixel_r3d))
;        moon_angles[*,center_index] = acos($
;            moon_r3ds[*,0]*pixel_r3d[*,0]+$
;            moon_r3ds[*,1]*pixel_r3d[*,1]+$
;            moon_r3ds[*,2]*pixel_r3d[*,2])
    endforeach
    moon_angles = reform(moon_angles,[nframe,image_size])*deg
    moon_weight = exp((2.5-moon_angles)/2.5)*2+1 ; decays to 1.

    sgtv, bytscl(reform(orig_images[0,*,*]), min=2000, max=20000, top=254), ct=49, position=[0,0,1,1]
    contour, reform(moon_angles[0,*,*]), position=[0,0,1,1], xstyle=5, ystyle=5, noerase=1, levels=[0,5,10,15,20,25,30], follow=1
    
    
    ; Moon's correction within 30 deg.
    
    ; Most significant correction for bright portion.
    
    
stop


;---For each pixel.
    img_bg = fltarr(image_size)
    img_stddev = fltarr(image_size)
    img_dt = fltarr(image_size)
    for ii=0,image_size[0]-1 do begin
        for jj=0,image_size[1]-1 do begin
            ;tmp = orig_images[*,ii,jj]
            tmp = ma_images[*,ii,jj]
            img_bg[ii,jj] = min(tmp)
            img_stddev[ii,jj] = stddev(tmp)
            img_dt[ii,jj] = mean(deriv(tmp))
        endfor
    endfor



stop

;---Remove fast varying signals.
    window_slow = width_slow*time_step
    imgs_slow = orig_images
    for index_id=0,ncenter_index-1 do begin
        ii = center_indices_2d[index_id,0]
        jj = center_indices_2d[index_id,1]
        imgs_slow[*,ii,jj] = calc_baseline_smooth(imgs_slow[*,ii,jj], window_slow, times)
    end
    stop
    return, newname

end


time_range = time_double(['2008-01-19/07:00','2008-01-19/08:00'])   ; moon and background fluctuations.
site = 'inuv'
test_time = '2008-01-19/07:04'
; moon center: 140,60
; moon reflection: 135,215
; moon edge: 130,70
; moon glow: 130,95

;time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])   ; stable arc.
;site = 'gako'
;test_time = '2016-10-13/12:10'
;; image edge: 20,120
;; stable arc: 100,50



;time_range = time_double(['2016-01-28/08:00','2016-01-28/09:00'])
;site = 'snkq'
;site = 'whit'
;test_time = '2016-01-28/08:47:30'
;
;time_range = time_double(['2008-02-13/02:00','2008-02-13/03:00'])   ; Chu+2015.
;site = 'gill'   ; gill, kuuj, snkq
;site = 'kuuj'   ; gill, kuuj, snkq
;; tree: 205,209
;;site = 'snkq'   ; gill, kuuj, snkq
;; moon edge: 40,120
;; moon: 45,120
;test_time = '2008-02-13/02:44'



asf_var = 'thg_'+site+'_asf'
asi_norm_var = asf_var+'_norm'
if check_if_update(asf_var, time_range) then begin
    asf_var = themis_read_asf(time_range, site=site)
endif
tic
var = themis_asi_cal_bg(time_range, site=site, asf_var=asf_var, newname=asi_norm_var)
toc
get_data, asi_norm_var, times, imgs_cal
end