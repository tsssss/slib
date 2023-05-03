;+
; Calibrate the background count for given asf image.
;-




; sample window does not significantly affect algorithm speed.
pro themis_asi_cal_brightness, asf_var, newname=newname

    if n_elements(newname) eq 0 then newname = asf_var+'_norm'
    get_data, asf_var, times, imgs_raw, limits=lim
    image_size = double(size(reform(imgs_raw[0,*,*]), dimensions=1))
    nframe = n_elements(times)
    time_step = 3d

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
    

;---A minimum background per pixel.
    imgs_bg = fltarr([nframe])
    tmp = reform(imgs_raw,[nframe,product(image_size)])
    for ii=0,nframe-1 do begin
        imgs_bg[ii] = min(tmp[ii,center_indices])
    endfor
    width_slow = 60
    imgs_bg = smooth(imgs_bg,width_slow, nan=1, edge_mirror=1)
    imgs_bg0 = fltarr([nframe,image_size])
    for ii=0,nframe-1 do imgs_bg0[ii,*,*] = imgs_bg[ii]

    
;---Remove fast varying signals.
    window_slow = width_slow*time_step
    imgs_slow = imgs_raw
    for index_id=0,ncenter_index-1 do begin
        ii = center_indices_2d[index_id,0]
        jj = center_indices_2d[index_id,1]
        imgs_slow[*,ii,jj] = calc_baseline(imgs_slow[*,ii,jj], window_slow, times)
    end
    
    
;---Prepare adpative window.
    sample_windows = [1,width_slow,600]*3
    nsample_window = n_elements(sample_windows)
    
    
;---Calculate the moon's elevation and azimuth.
    site_glon = lim.asc_glon
    site_glat = lim.asc_glat
    moon_elevs = moon_elev(times, site_glon, site_glat, $
        azimuth=moon_azims)
    moon_xpos = cos(moon_elevs)*cos(moon_azims)
    moon_ypos = cos(moon_elevs)*sin(moon_azims)
    moon_zpos = sin(moon_elevs)


;---Calculate the angle between each pixel and the moon.
    moon_angles = fltarr([nframe,product(image_size)])
    foreach center_index, center_indices do begin
        pixel_elev = pixel_elevs[center_index]
        pixel_azim = pixel_azims[center_index]
        pixel_xpos = cos(pixel_elev)*cos(pixel_azim)
        pixel_ypos = cos(pixel_elev)*sin(pixel_azim)
        pixel_zpos = sin(pixel_elev)
        moon_angles[*,center_index] = acos(moon_xpos*pixel_xpos+moon_ypos*pixel_ypos+moon_zpos*pixel_zpos)
    endforeach
    moon_angles = reform(moon_angles,[nframe,image_size])*deg
    moon_weight = exp((2.5-moon_angles)/2.5)*2+1 ; decays to 1.

    
;---Calulate the background of imgs_slow.
    max_count = 65535
    norm_count = round(imgs_slow*moon_weight)<max_count
    norm_windows = exp((max_count-norm_count+1e4)/1e4)*2+3
    
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
    
    imgs_cal = imgs_raw-imgs_bg
    imgs_cal = reform(imgs_cal,[nframe,product(image_size)])
    bg0 = fltarr(nframe)
    for kk=0,nframe-1 do begin
        index = where(moon_angles[kk,*,*] ge 40, count)
        tmp = imgs_cal[kk,index]
        tmp = tmp[sort(tmp)]
        bg0[kk] = tmp[0.1*count]
    endfor
    bg0 = smooth(bg0,width_slow,nan=1,edge_mirror=1)
    imgs_cal = reform(imgs_cal,[nframe,image_size])
    for kk=0,nframe-1 do begin
        imgs_cal[kk,*,*] -= bg0[kk]
    endfor
    imgs_cal >= 0
    
    store_data, newname, times, imgs_cal, limits=lim
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