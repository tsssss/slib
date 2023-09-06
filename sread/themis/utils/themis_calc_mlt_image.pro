;+
; This program uses smoothing to calibrate the brightness and do not generate cdf files.
;
; calibrate_method=. 'normal' or 'smooth'. 'normal for using the weight system. 'smooth' works better for streamer only.
;-

function themis_calc_mlt_image, input_time_range, sites=sites, $
    min_elev=min_elev, merge_method=merge_method, calibrate_method=calibrate_method, smooth_window=smooth_window, _extra=extra

    errmsg = ''
    retval = ''
    time_range = time_double(input_time_range)
    if n_elements(sites) eq 0 then sites = themis_asi_read_available_sites(time_range)
    if n_elements(min_elev) eq 0 then min_elev = 5d
    if n_elements(merge_method) eq 0 then merge_method = 'merge_elev'
    if n_elements(calibrate_method) eq 0 then calibrate_method = 'normal'
    if n_elements(smooth_window) eq 1 then calibrate_method = 'smooth'

    ; Collect merge info for the given sites.
    themis_asf_read_mlon_image_gen_merge_info, sites=sites, min_elev=min_elev, merge_method=merge_method
    merge_weight = get_var_data('thg_mlon_image_merge_weight')

    ; Load and merge mlon image at each site.
    image_size = size(merge_weight[sites[0]], dimensions=1)
    time_step = 3d
    common_times = make_bins(time_range+[0,-1]*time_step, time_step)
    ntime = n_elements(common_times)
    mlon_images = fltarr([ntime,image_size])
    illuminated_pixels = fltarr(image_size)

    foreach site, sites do begin
        weight = merge_weight[site]
        index = where(weight ne 0, count)
        if count eq 0 then continue

        ; Calculate MLon image directly.
        pad_time = 5d*60
        data_time_range = time_range+[-1,1]*pad_time
        asf_var = themis_read_asf(data_time_range, site=site, errmsg=errmsg)
        if errmsg ne '' then continue

        ; Calibrate brightness before mapping works better.
        asf_cal_var = asf_var+'_cal'
        if calibrate_method eq 'normal' then begin
            themis_asi_cal_brightness, asf_var, newname=asf_cal_var
        endif else begin
            themis_asi_cal_brightness_smooth, asf_var, newname=asf_cal_var, smooth_window=smooth_window
        endelse
        themis_calc_asf_mlon_image_per_site, asf_cal_var, errmsg=errmsg
        if errmsg ne '' then return, retval

        ; Map calibrate images to the wanted times.
        the_var = 'thg_'+site+'_mlon_image'
        get_data, the_var, uts, images, limits=lim
        
        crop_xrange = lim.crop_xrange
        crop_yrange = lim.crop_yrange
        the_image_size = lim.image_size

        weight_crop = weight[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        index_crop = where(weight ne 0, count)
        
        ; Map to common time.
        index = where_pro(uts, '[]', common_times[[0,ntime-1]], count=count)
        if count eq 0 then continue
        uts = uts[index]
        images = images[index,*,*]        
        for ii=0,count-1 do images[ii,*,*] *= weight_crop
        
        index = (uts-common_times[0])/time_step
        mlon_images[index,crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]] += images
        illuminated_pixels[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]] += weight_crop
    endforeach

    mlon_image_var = 'thg_asf_mlon_image'
    store_data, mlon_image_var, common_times, mlon_images
    mlon_image_info = mlon_image_info()
    mlon_image_info['display_type'] = 'image'
    mlon_image_info['unit'] = 'Count #'
    mlon_image_info['min_elev'] = min_elev
    mlon_image_info['illuminated_pixels'] = illuminated_pixels ne 0
    add_setting, mlon_image_var, smart=1, mlon_image_info

;---Rotate from mlon to mlt.
    mlt_image_var = 'thg_asf_mlt_image'
    mlon_image_to_mlt_image, mlon_image_var, to=mlt_image_var

    return, mlt_image_var

end

time_range = time_double(['2008-01-19/06:00','2008-01-19/09:00'])
time_range = time_double(['2008-01-19/07:00','2008-01-19/07:10'])
sites = ['fsim','gill','inuv']
smooth_window = 60*0.5
min_elev = 2.5
var = themis_calc_mlt_image(time_range, sites=sites, smooth_window=smooth_window, min_elev=min_elev)
end