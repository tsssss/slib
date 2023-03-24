;+
; To read ASF mlon image.
; This is to replace themis_read_mlonimg_per_site
;
; asf_var. A string for the asf var in tplot.
; no_crop=. A boolean. Set to return the overall mlon image.
;   By default, we return the cropped image for the mlon/mlat covered by the current ASI.
;-

pro themis_calc_asf_mlon_image_per_site, asf_var, errmsg=errmsg, no_crop=no_crop

;---Map ASF image to MLon-MLat image.
    if n_elements(asf_var) eq 0 then begin
        errmsg = 'No input asf_var ...'
        return
    endif
    get_data, asf_var, times, asf_images, limits=lim
    if n_elements(times) eq 0 and times[0] eq 0 then begin
        errmsg = 'No input data ...'
        return
    endif
    crop = 1
    if keyword_set(no_crop) then crop = 0
    site = strlowcase(lim.site)
    mlon_images = mlon_image_map_old2new(asf_images, site=site, crop=crop)
    pixel_elev = mlon_image_map_old2new(lim.pixel_elev, site=site, crop=crop)
    pixel_azim = mlon_image_map_old2new(lim.pixel_azim, site=site, crop=crop)

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
    if crop then begin
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
        'site', lim.site, $
        'asc_glon', lim.asc_glon, $
        'asc_glat', lim.asc_glat, $
        'pixel_mlon', pixel_mlon, $
        'pixel_mlat', pixel_mlat, $
        'pixel_elev', pixel_elev, $
        'pixel_azim', pixel_azim, $
        'pixel_xpos', pixel_xpos, $
        'pixel_ypos', pixel_ypos, $
        'crop_xrange', crop_xrange, $
        'crop_yrange', crop_yrange )
end


time_range = time_double(['2013-03-17/07:00','2013-03-17/08:00'])
site = 'fykn'
time_range = time_double(input_time_range)
asf_var = themis_read_asf(time_range, site=site, errmsg=errmsg)
themis_calc_asf_mlon_image_per_site, asf_var, crop=1
themis_asi_cal_brightness, mlon_image_var, newname=mlon_image_var+'_norm'
end
