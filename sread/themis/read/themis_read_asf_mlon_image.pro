;+
; Read ASF mlon image.
; This is to replace themis_read_mlonimg_per_site
;-

pro themis_read_asf_mlon_image, input_time_range, sites=sites, $
    min_elev=min_elev, merge_method=merge_method, errmsg=errmsg

    errmsg = ''
    time_range = time_double(input_time_range)
    if n_elements(sites) eq 0 then sites = themis_read_asi_available_sites(time_range)

    if n_elements(min_elev) eq 0 then min_elev = 5d
    if n_elements(merge_method) eq 0 then merge_method = 'merge_elev'

    ; Collect merge info for the given sites.
    themis_read_asf_mlon_image_gen_merge_info, sites=sites, min_elev=min_elev, merge_method=merge_method
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

        themis_read_mlon_image_per_site, time_range, site=site, errmsg=errmsg
        if errmsg ne '' then continue
        the_var = 'thg_'+site+'_mlon_image'
        get_data, the_var, uts, images, limits=lim
        
        crop_xrange = lim.crop_xrange
        crop_yrange = lim.crop_yrange
        the_image_size = lim.image_size

        weight_crop = weight[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        index_crop = where(weight ne 0, count)
        
        ; Map to common time.
        index = lazy_where(uts, '[]', common_times[[0,ntime-1]], count=count)
        if count eq 0 then continue
        uts = uts[index]
        images = images[index,*,*]        
        for ii=0,count-1 do images[ii,*,*] *= weight_crop
        
        index = (uts-common_times[0])/time_step
        mlon_images[index,crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]] += images
        illuminated_pixels[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]] += weight_crop
    endforeach

    var = 'thg_asf_mlon_image'
    store_data, var, common_times, mlon_images
    mlon_image_info = mlon_image_info()
    mlon_image_info['display_type'] = 'image'
    mlon_image_info['unit'] = 'Count #'
    mlon_image_info['min_elev'] = min_elev
    mlon_image_info['illuminated_pixels'] = illuminated_pixels ne 0
    add_setting, var, smart=1, mlon_image_info

end

    time_range = time_double(['2013-03-17/07:00','2013-03-17/08:00'])
    sites = ['mcgr','fykn','gako','fsim', $
        'fsmi','tpas','gill','snkq','pina','kapu']
    
    time_range = time_double(['2019-03-28/08:00','2019-03-28/09:00'])
;    sites = ['inuv','whit','atha','tpas','gill','rank']
    sites = ['inuv','whit']
    
themis_read_asf_mlon_image, time_range, sites=sites, merge_method='merge_elev', min_elev=2.5
end
