;+
; To read ASF mlon image.
; This is to replace themis_read_mlonimg_per_site
;
; input_time_range. The input time range in unix time or string.
; site=. A string for a given ASI site.
; no_crop=. A boolean. Set to return the overall mlon image.
;   By default, we return the cropped image for the mlon/mlat covered by the current ASI.
;-

pro themis_calc_asf_mlon_image_per_site, input_time_range, site=site, errmsg=errmsg, no_crop=no_crop

;---Read ASF image.
    time_range = time_double(input_time_range)
    themis_read_asf, time_range, site=site, errmsg=errmsg
    if errmsg ne '' then return

;---Map ASF image to MLon-MLat image.
    mlon_image_info = mlon_image_info()
    image_size = mlon_image_info.image_size
    image_pos = [0d,0]
    pixel_mlon = mlon_image_info.pixel_mlon
    pixel_mlat = mlon_image_info.pixel_mlat
    pixel_xpos = mlon_image_info.pixel_xpos
    pixel_ypos = mlon_image_info.pixel_ypos
    crop_xrange = [0,image_size[0]-1]
    crop_yrange = [0,image_size[1]-1]

;---Get the MLon image and its pixel positions.
    crop = 1
    if keyword_set(no_crop) then crop = 0
    if crop then begin
        asf_var = 'thg_'+site+'_asf'
        get_data, asf_var, times, asf_images, limits=lim
        mlon_images = mlon_image_map_old2new(asf_images, site=site, crop=crop)
        pixel_elev = mlon_image_map_old2new(lim.pixel_elev, site=site, crop=crop)

        prefix = 'thg_'+site+'_mlon_image_'
        crop_xrange = get_var_data(prefix+'crop_xrange')
        crop_yrange = get_var_data(prefix+'crop_yrange')
        pixel_mlon = pixel_mlon[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        pixel_mlat = pixel_mlat[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        pixel_xpos = pixel_xpos[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        pixel_ypos = pixel_ypos[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        image_pos = [crop_xrange[0],crop_yrange[0]]
        image_size = size(pixel_mlon, dimensions=1)
    endif

    mlon_image_var = 'thg_'+site+'_mlon_image'
    store_data, mlon_image_var, times, mlon_images
    add_setting, mlon_image_var, smart=1, dictionary($
        'display_type', 'image', $
        'unit', 'Count #', $
        'image_size', image_size, $ ; image size of the mlon image.
        'image_pos', image_pos, $   ; image's lower left corner in the overall image.
        'pixel_mlon', pixel_mlon, $
        'pixel_mlat', pixel_mlat, $
        'pixel_elev', pixel_elev, $
        'pixel_xpos', pixel_xpos, $
        'pixel_ypos', pixel_ypos, $
        'crop_xrange', crop_xrange, $
        'crop_yrange', crop_yrange )
end


time_range = time_double(['2013-03-17/07:00','2013-03-17/08:00'])
site = 'fykn'
themis_calc_asf_mlon_image_per_site, time_range, site=site, crop=1
themis_asi_cal_brightness, mlon_image_var, newname=mlon_image_var+'_norm'
end
