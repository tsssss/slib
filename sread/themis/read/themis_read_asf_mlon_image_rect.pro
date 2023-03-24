;+
; Adopted from themis_read_mlonimg.
;-

function themis_read_asf_mlon_image_rect, input_time_range, sites=sites, $
    min_elev=min_elev, merge_method=merge_method, errmsg=errmsg, get_name=get_name


    errmsg = ''
    mlon_image_var = 'thg_asf_mlon_image_rect'
    if keyword_set(get_name) then return, mlon_image_var

    time_range = time_double(input_time_range)
    if n_elements(sites) eq 0 then sites = themis_asi_read_available_sites(time_range)
    if n_elements(min_elev) eq 0 then min_elev = 5d
    if n_elements(merge_method) eq 0 then merge_method = 'merge_elev'


    ; Collect merge info for the given sites.
    merge_weight = get_var_data(themis_read_asf_mlon_image_rect_gen_merge_info($
        sites=sites, min_elev=min_elev, merge_method=merge_method))

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

        the_var = themis_read_mlon_image_rect_per_site(time_range, site=site, errmsg=errmsg)
        if errmsg ne '' then continue
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

    store_data, mlon_image_var, common_times, mlon_images
    mlon_image_info = mlon_image_rect_info()
    mlon_image_info['display_type'] = 'image'
    mlon_image_info['unit'] = 'Count #'
    mlon_image_info['min_elev'] = min_elev
    mlon_image_info['illuminated_pixels'] = illuminated_pixels ne 0
    add_setting, mlon_image_var, smart=1, mlon_image_info

    return, mlon_image_var

end

time_range = time_double(['2013-05-01/07:20','2013-05-01/07:50'])
sites = ['atha']
site = 'atha'
the_var = themis_read_mlon_image_rect_per_site(time_range, site=site, errmsg=errmsg)
stop
var = themis_read_asf_mlon_image_rect(time_range, sites=sites)
end