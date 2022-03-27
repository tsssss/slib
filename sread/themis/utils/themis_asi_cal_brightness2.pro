;+
; Calibrate the background count for given asf image.
;-

function calc_baseline, asi_raw, window, times

    ; Truncate data into sectors of the wanted window
    nframe = n_elements(asi_raw)
    sec_times = make_bins(minmax(times), window, inner=1)
    time_step = 3
    sec_pos = (sec_times-times[0])/time_step
    nsec = n_elements(sec_pos)-1
    frames = dindgen(nframe)

    ; Get the min value within each sector.
    xxs = fltarr(nsec)
    yys = fltarr(nsec)
    for kk=0,nsec-1 do begin
        yys[kk] = min(asi_raw[sec_pos[kk]:sec_pos[kk+1]-1], index)
        ;xxs[kk] = sec_pos[kk]+index  ; This causes weird result.
        xxs[kk] = (sec_pos[kk]+sec_pos[kk+1])*0.5
    endfor
;    ; Add sample points at the beginning and end of the raw data.
    txs = frames[sec_pos[0]:sec_pos[1]]
    tys = asi_raw[sec_pos[0]:sec_pos[1]]
    res = linfit(txs,tys)
    ty = (yys[0]-(xxs[0]-0)*res[1])>min(tys)
    xxs = [0,xxs]
    yys = [ty,yys]
    
    txs = frames[sec_pos[-2]:sec_pos[-1]]
    tys = asi_raw[sec_pos[-2]:sec_pos[-1]]
    res = linfit(txs,tys)
    ty = (yys[-1]+(nframe-1-xxs[-1])*res[1])>min(tys)
    xxs = [xxs,nframe-1]
    yys = [yys,ty]

    ; Smooth after interpolation to make the background continuous.
    time_bg = smooth(interpol(yys,xxs,frames), window*0.5, edge_mirror=1)
    return, time_bg

end


; sample window does not significantly affect algorithm speed.
pro themis_asi_cal_brightness, asf_var, $
    newname=newname, to=newname2

    if n_elements(newname) eq 0 then newname = asf_var+'_norm'
    if n_elements(newname2) eq 1 then newname = newname2
    get_data, asf_var, times, imgs_raw, limits=lim
    image_size = size(reform(imgs_raw[0,*,*]), dimensions=1)
    nframe = n_elements(times)
    max_count = 65535

;---Mapping the count to wanted window.
    width_range = [1,600]
    counts = findgen(max_count+1)
    widths = (1-tanh((counts-2e4)/1e4))*0.5*(width_range[1]-width_range[0]-1)+width_range[0]


;---Calculate an overall background to extract fast moving structures.
    rad = constant('rad')
    pixel_elevs = lim.pixel_elev*rad
    pixel_azims = lim.pixel_azim*rad
    edge_indices = where(finite(pixel_elevs,nan=1) or pixel_elevs le 0, $
        complement=center_indices, nedge_index)
    
    imgs_edge = fltarr([nframe,nedge_index])
    foreach time, times, time_id do begin
        timg = reform(imgs_raw[time_id,*,*])
        imgs_edge[time_id,*] = timg[edge_indices]
    endforeach
    bg_edge = median(imgs_edge)
    imgs_bg = (imgs_raw-bg_edge)>0

;---Calculate the moon's elevation and azimuth.
    site_glon = lim.asc_glon
    site_glat = lim.asc_glat
    moon_elevs = moon_elev(times, site_glon, site_glat, $
        azimuth=moon_azims)
    moon_xpos = cos(moon_elevs)*cos(moon_azims)
    moon_ypos = cos(moon_elevs)*sin(moon_azims)
    moon_zpos = sin(moon_elevs)

    
;---Process each pixel.
    foreach center_index, center_indices do begin
        tmp = array_indices(image_size, dimensions=1, center_index)
        ii = tmp[0]
        jj = tmp[1]
        
        ; Deal with special situations.
        bg = imgs_bg[*,ii,jj]
        bg_min = min(bg)
        if bg_min eq max(bg) then begin
            continue
        endif
        bg = bg-bg_min

        ; Calculate the distance from the moon.
        pixel_elev = pixel_elevs[ii,jj]
        pixel_azim = pixel_azims[ii,jj]
        pixel_xpos = cos(pixel_elev)*cos(pixel_azim)
        pixel_ypos = cos(pixel_elev)*sin(pixel_azim)
        pixel_zpos = sin(pixel_elev)
        moon_dis = sqrt((moon_xpos-pixel_xpos)^2+(moon_ypos-pixel_ypos)^2+(moon_zpos-pixel_zpos)^2)

        ; Calculate the background at the wanted window.
        moon_weight = 0.5-tanh((moon_dis-0.2)/0.1)*0.5  ; in [0,1]
        moon_weight = 0.5-tanh((moon_dis-0.3)/0.1)*0.5  ; in [0,1]
        bg1 = calc_baseline(bg*moon_weight, 30, times)
        value_weight = (1+tanh((bg1-0.5e4)/2e4))*0.5
        imgs_bg[*,ii,jj] = bg1*value_weight+bg_min
        

;if min(moon_dis) lt 0.05 then begin
;    plot, bg+1, ylog=1
;;    oplot, bg*moon_weight
;    oplot, bg1
;    oplot, bg1*value_weight
;    stop
;endif

;        plot, bg
;        oplot, imgs_bg[*,ii,jj]
;        oplot, !x.crange, bg_min+[0,0], linestyle=1
;        stop
    endforeach
    
    index = where(imgs_raw eq max_count*0.8, count)
    if count ne 0 then imgs_bg[index] = imgs_raw[index]
    
    store_data, newname, times, imgs_raw-imgs_bg, limits=lim
end



time_range = time_double(['2016-01-28/08:00','2016-01-28/09:00'])
site = 'snkq'
site = 'whit'
test_time = '2016-01-28/08:47:30'

time_range = time_double(['2008-01-19/07:00','2008-01-19/08:00'])   ; moon and background fluctuations.
site = 'inuv'
test_time = '2008-01-19/07:04'
;
;time_range = time_double(['2016-10-13/13:00','2016-10-13/13:00'])   ; stable arc.
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
time_range = time_double(['2013-03-17/07:00','2013-03-17/08:00'])   ; gabrielse's example
site = 'gako'
time_range = time_double(['2013-03-17/06:00','2013-03-17/09:00'])   ; gabrielse's example
site = 'gako'



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
