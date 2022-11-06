;+
; Calibrate the background count for given asf image.
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



; sample window does not significantly affect algorithm speed.
pro themis_asi_cal_brightness_smooth, asf_var, newname=newname, smooth_window=smooth_window

    if n_elements(newname) eq 0 then newname = asf_var+'_norm'
    get_data, asf_var, times, imgs_raw, limits=lim
    image_size = double(size(reform(imgs_raw[0,*,*]), dimensions=1))
    nframe = n_elements(times)
    if n_elements(smooth_window) eq 0 then smooth_window = 2.5*60d  ; sec


;---Calculate the background of edge pixels.    
    deg = constant('deg')
    rad = constant('rad')
    pixel_elevs = lim.pixel_elev*rad
    pixel_azims = lim.pixel_azim*rad

    edge_indices = where(finite(pixel_elevs,nan=1) or pixel_elevs le 0, nedge_index, $
        complement=center_indices, ncomplement=ncenter_index)
    center_indices_2d = fltarr(ncenter_index,2)
    center_indices_2d[*,0] = center_indices mod image_size[0]
    center_indices_2d[*,1] = (center_indices-center_indices_2d[*,0])/image_size[0]

    imgs_slow = imgs_raw
    for index_id=0,ncenter_index-1 do begin
        ii = center_indices_2d[index_id,0]
        jj = center_indices_2d[index_id,1]
        imgs_slow[*,ii,jj] = calc_baseline_smooth(imgs_slow[*,ii,jj], smooth_window, times)
    end

    store_data, newname, times, imgs_raw-imgs_slow, limits=lim
    return
    

;    imgs_edge = fltarr([nframe,nedge_index])
;    foreach time, times, time_id do begin
;        timg = reform(imgs_raw[time_id,*,*])
;        imgs_edge[time_id,*] = timg[edge_indices]
;    endforeach
;    bg_edge = median(imgs_edge)
       

;;---Calculate the moon's elevation and azimuth.
;    site_glon = lim.asc_glon
;    site_glat = lim.asc_glat
;    moon_elevs = moon_elev(times, site_glon, site_glat, $
;        azimuth=moon_azims)
;    moon_xpos = cos(moon_elevs)*cos(moon_azims)
;    moon_ypos = cos(moon_elevs)*sin(moon_azims)
;    moon_zpos = sin(moon_elevs)


;;---Calculate the angle between each pixel and the moon.
;    moon_angles = fltarr([nframe,product(image_size)])
;    foreach center_index, center_indices do begin
;        pixel_elev = pixel_elevs[center_index]
;        pixel_azim = pixel_azims[center_index]
;        pixel_xpos = cos(pixel_elev)*cos(pixel_azim)
;        pixel_ypos = cos(pixel_elev)*sin(pixel_azim)
;        pixel_zpos = sin(pixel_elev)
;        moon_angles[*,center_index] = acos(moon_xpos*pixel_xpos+moon_ypos*pixel_ypos+moon_zpos*pixel_zpos)
;    endforeach
;    moon_angles = reform(moon_angles,[nframe,image_size])*deg
;;    moon_weight = 0.5-tanh((moon_angles-35)/7.5)*0.5
;    moon_weight = exp((10-moon_angles)/5)+1 ; decays to 1.
    
    
;;---Prepare adpative window.
;    max_count = 65535
;    sample_windows = [1,60,600]*3
;    nsample_window = n_elements(sample_windows)
    
    
;---A minimum background per pixel.
    img_bg = fltarr(image_size)
    for index_id=0,ncenter_index-1 do begin
        ii = center_indices_2d[index_id,0]
        jj = center_indices_2d[index_id,1]
        img_bg[ii,jj] = min(imgs_raw[*,ii,jj])
    end
    img_bg = smooth(img_bg, image_size*0.1, edge_mirror=1)
    
    imgs_bg0 = fltarr([nframe,image_size])
    for index_id=0,ncenter_index-1 do begin
        ii = center_indices_2d[index_id,0]
        jj = center_indices_2d[index_id,1]
        imgs_bg0[*,ii,jj] = img_bg[ii,jj]
    end

    
;---Calulate the background of imgs_slow.
    norm_count = round(imgs_slow*moon_weight)<max_count
    norm_windows = (1-tanh((norm_count-0.5e4)/2.5e4))*0.5*(600-3)+3 ; in [n,m,n].
    
    index = where(norm_windows ge sample_windows[1], count, complement=index2, ncomplement=count2)
    imgs_bg = fltarr([nframe,image_size])
    if count ne 0 then begin
        weights = (norm_windows[index]-sample_windows[1])/(sample_windows[2]-sample_windows[1])
        imgs_bg[index] = weights*imgs_bg0[index]+(1-weights)*imgs_slow[index]
    endif
    if count2 ne 0 then begin
        weights = (norm_windows[index2]-sample_windows[0])/(sample_windows[1]-sample_windows[0])
        imgs_bg[index2] = weights*imgs_slow[index2]+(1-weights)*imgs_raw[index2]
    endif
    imgs_bg = imgs_slow
    
    store_data, newname, times, imgs_raw-imgs_bg, limits=lim
end



time_range = time_double(['2016-01-28/08:00','2016-01-28/09:00'])
site = 'snkq'
site = 'whit'
test_time = '2016-01-28/08:47:30'

time_range = time_double(['2008-01-19/07:00','2008-01-19/08:00'])   ; moon and background fluctuations.
site = 'inuv'
test_time = '2008-01-19/07:04'

;time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])   ; stable arc.
;site = 'gako'
;test_time = '2016-10-13/12:10'
;
;time_range = time_double(['2015-12-02/08:00','2015-12-02/09:00'])   ; Homayon example.
;site = 'rank'
;test_time = '2015-12-02/08:10'
;
;time_range = time_double(['2008-02-13/02:00','2008-02-13/03:00'])   ; Chu+2015.
;site = 'gill'   ; gill, kuuj, snkq
;test_time = '2008-02-13/02:44'

;time_range = time_double(['2015-10-05/09:00','2015-10-05/10:00'])   ; Homayon example
;site = 'snkq'
;
;time_range = time_double(['2015-12-07/08:00','2015-12-07/09:00'])   ; Homayon example
;site = 'inuv'   ;'kuuj','gill','rank','fsim'
;
;time_range = time_double(['2013-03-17/08:00','2013-03-17/09:00'])   ; garbrielse's example
;site = 'gako'
;time_range = time_double(['2013-03-17/05:00','2013-03-17/06:30'])   ; garbrielse's example
;site = 'mcgr'
time_range = time_double(['2013-03-17/05:00','2013-03-17/06:30'])   ; garbrielse's example
site = 'fsim'


asf_var = 'thg_'+site+'_asf'
asi_norm_var = asf_var+'_norm'
if check_if_update(asf_var, time_range) then begin
    themis_read_asf, time_range, site=site
endif
tic
themis_asi_cal_brightness, asf_var, newname=asi_norm_var
toc
get_data, asi_norm_var, times, imgs_cal
end