;+
; Read and calibrate asf images per night.
;-



function themis_asf_read_per_night, input_time_range, site=site

    errmsg = ''
    retval = !null

tic


;---Handle input.
    time_range = time_double(input_time_range)
    secofday = constant('secofday')
    secofhour = constant('secofhour')
    date = mean(time_range)
    date = date-(date mod secofday)
    
    var = 'thg_asf_'+site+'_'+time_string(date,tformat='YYYY_MMDD')
    if tnames(var) eq '' then begin
        info = dictionary($
            'site', site, $
            'date', date )
        store_data, var, 0, info
    endif
    info = get_var_data(var)

    
;---Get the file_times for the given date.
    if ~info.haskey('file_times') then begin
        site_info = themis_asi_read_site_info(site)
        midn_ut = date+site_info['midn_ut']
        search_time_range = midn_ut+[-1,1]*9*secofhour
        file_times = themis_asi_read_available_file_times(search_time_range, site=site)
        info['file_times'] = file_times
        store_data, var, 0, info
    endif
    file_times = info['file_times']
    nfile_time = n_elements(file_times)
    if nfile_time eq 0 then return, retval

    
;---Get the exact start and end times for each site.
    if ~info.haskey('time_range') then begin
        asf_var = themis_read_asf(min(file_times)+[0,secofhour], site=site)
        get_data, asf_var, times
        start_time = min(times)
        asf_var = themis_read_asf(max(file_times)+[0,secofhour], site=site)
        get_data, asf_var, times
        end_time = max(times)
        time_range = [start_time,end_time]
        info['time_range'] = time_range
        store_data, var, 0, info
    endif
    time_range = info['time_range']
    

;;---Check moon elevation.
;    min_moon_elev = 0d
;    var_info = themis_asi_read_moon_pos(time_range, site=site, get_name=1)
;    moon_elev_var = var_info['moon_elev']
;    moon_azim_var = var_info['moon_azim']
;    if ~info.haskey('moon_time_range') then begin
;        if check_if_update(moon_elev_var, time_range) then var_info = themis_asi_read_moon_pos(time_range, site=site)
;        moon_elevs = get_var_data(moon_elev_var, times=times)
;        index = where(moon_elevs ge min_moon_elev, count)
;        if count ne 0 then begin
;            moon_time_range = times[minmax(index)]
;        endif else begin
;            moon_time_range = !null
;        endelse
;        info['moon_time_range'] = moon_time_range
;        store_data, var, 0, info
;    endif
;    moon_time_range = info['moon_time_range']
    
    

;---The calibrated image.
    image_var = asf_var+'_calibrated'
    if ~check_if_update(image_var, time_range) then return, image_var


;---Read original asf images.
    asf_var = themis_read_asf(time_range, site=site, get_name=1)
    if check_if_update(asf_var, time_range) then begin
        asf_var = themis_read_asf(time_range, site=site)
    endif
    get_data, asf_var, common_times, orig_images, limits=lim
    image_size = lim.image_size
    npixel = product(image_size)
    nframe = n_elements(common_times)
    time_step = common_times[1]-common_times[0]


;---Seperate edge and center pixels.
    deg = constant('deg')
    rad = constant('rad')
    pixel_elevs = lim.pixel_elev
    pixel_azims = lim.pixel_azim

    edge_indices = where(finite(pixel_elevs,nan=1) or pixel_elevs le 0, nedge_index, $
        complement=center_indices, ncomplement=ncenter_index)
    center_indices_2d = fltarr(ncenter_index,2)
    center_indices_2d[*,0] = center_indices mod image_size[0]
    center_indices_2d[*,1] = (center_indices-center_indices_2d[*,0])/image_size[0]
    edge_indices_2d = fltarr(nedge_index,2)
    edge_indices_2d[*,0] = edge_indices mod image_size[0]
    edge_indices_2d[*,1] = (edge_indices-edge_indices[*,0])/image_size[0]


;---A minimum background per pixel.
    imgs_bg0 = fltarr([nframe,image_size])
    for ii=0,image_size[0]-1 do begin
        for jj=0,image_size[1]-1 do begin
            imgs_bg0[*,ii,jj] = min(orig_images[*,ii,jj])
        endfor
    endfor
    
    
    
;---A adaptive background.   
    imgs_slow = reform(orig_images, [nframe,npixel])
    value_bins = make_bins([0,65535], 3e3, inner=1)
    min_durations = exp(value_bins/1e4)
    min_durations = (1-(min_durations-1)/(max(min_durations)-1))*600+1
    foreach index, center_indices, index_id do begin
;        if center_indices_2d[index_id,0] ne 120 then continue
;        if center_indices_2d[index_id,1] ne 64 then continue
;        stop
        
;        the_data0 = smooth(imgs_slow[*,index], 60, edge_mirror=1)
        the_data0 = smooth(imgs_slow[*,index], 60, edge_mirror=1)
        bg_values = imgs_bg0[*,center_indices_2d[index_id,0],center_indices_2d[index_id,1]]
        weight = (tanh((the_data0-bg_values-0.5e4)/0.5e4)+1)*0.5
        the_data = weight*the_data0+(1-weight)*bg_values
        sample_indexs = []
        foreach value, value_bins, value_id do begin
            tindex = where(the_data ge value, count)
            if count eq 0 then continue
            the_index = time_to_range(tindex,time_step=1)
            durations = the_index[*,1]-the_index[*,0]
            the_duration = min_durations[value_id]
            tindex = where(durations ge the_duration, count)
            if count eq 0 then continue
            the_index = the_index[tindex,*]
            sample_indexs = [sample_indexs,the_index]
        endforeach
        sample_indexs = sort_uniq(sample_indexs)
        nsample_index = n_elements(sample_indexs)
        for ii=1,nsample_index-1 do begin
            i0 = sample_indexs[ii-1]+600
            i1 = sample_indexs[ii]-600
            if i0 gt i1 then continue
            iis = make_bins([i0,i1], 1200, inner=1)
            if n_elements(iis) eq 0 then continue
            sample_indexs = [sample_indexs,iis]
        endfor
        sample_indexs = sort_uniq(sample_indexs)
        sample_values = the_data[sample_indexs]
        
        sample_bg = interpol(sample_values, common_times[sample_indexs], common_times)
        smooth_widths = scale_value_to_smooth_width(sample_bg)<1200

        imgs_slow[*,index] = smooth_pro(the_data, smooth_widths)
    endforeach
    imgs_slow = reform(imgs_slow, [nframe,image_size])
    store_data, image_var, common_times, orig_images-imgs_slow, limits=lim
toc

end




time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])   ; stable arc.
site = 'gako'
;test_time = '2016-10-13/12:10'
;; image edge: 20,120
;; stable arc: 100,50

;time_range = time_double(['2008-01-19/07:00','2008-01-19/08:00'])   ; moon and background fluctuations.
;site = 'inuv'
;test_time = '2008-01-19/07:04'

time_range = time_double(['2008-02-13/02:00','2008-02-13/03:00'])   ; Chu+2015.
site = 'gill'   ; gill, kuuj, snkq
;test_time = '2008-02-13/02:44'


;time_range = time_double(['2015-04-02/07:00','2015-04-02/08:00'])   ; Random example.
;site = 'fsmi'
;;site = 'pina'


tmp = themis_asf_read_per_night(time_range, site=site)
end