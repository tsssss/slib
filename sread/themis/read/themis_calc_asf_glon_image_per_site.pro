;+
; To read ASF glon image.
;
; asf_var. A string for the asf var in tplot.
; no_crop=. A boolean. Set to return the overall glon image.
;   By default, we return the cropped image for the glon/glat covered by the current ASI.
;-

pro themis_calc_asf_glon_image_per_site, asf_var, errmsg=errmsg, no_crop=no_crop

;---Map ASF image to GLon-GLat image.
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
    glon_images = glon_image_map_old2new(asf_images, site=site, crop=crop)
    pixel_elev = glon_image_map_old2new(lim.pixel_elev, site=site, crop=crop)
    pixel_azim = glon_image_map_old2new(lim.pixel_azim, site=site, crop=crop)

    glon_image_info = glon_image_info()
    image_size = glon_image_info.image_size
    image_pos = [0d,0]
    pixel_glon = glon_image_info.pixel_glon
    pixel_glat = glon_image_info.pixel_glat
    pixel_xpos = glon_image_info.pixel_xpos
    pixel_ypos = glon_image_info.pixel_ypos
    crop_xrange = [0,image_size[0]-1]
    crop_yrange = [0,image_size[1]-1]

;---Get the GLon image and its pixel positions.
    if crop then begin
        prefix = 'thg_'+site+'_glon_image_'
        crop_xrange = get_var_data(prefix+'crop_xrange')
        crop_yrange = get_var_data(prefix+'crop_yrange')
        crop_xrange >= 0
        crop_xrange <= image_size[0]-1
        crop_yrange >= 0
        crop_yrange <= image_size[1]-1
        pixel_glon = pixel_glon[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        pixel_glat = pixel_glat[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        pixel_xpos = pixel_xpos[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        pixel_ypos = pixel_ypos[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        image_pos = [crop_xrange[0],crop_yrange[0]]
        image_size = size(pixel_glon, dimensions=1)
    endif

    glon_image_var = 'thg_'+site+'_glon_image'
    store_data, glon_image_var, times, glon_images
    add_setting, glon_image_var, smart=1, dictionary($
        'display_type', 'image', $
        'unit', 'Count #', $
        'image_size', image_size, $ ; image size of the glon image.
        'image_pos', image_pos, $   ; image's lower left corner in the overall image.
        'site', lim.site, $
        'asc_glon', lim.asc_glon, $
        'asc_glat', lim.asc_glat, $
        'pixel_glon', pixel_glon, $
        'pixel_glat', pixel_glat, $
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
themis_read_asf, time_range, site=site, errmsg=errmsg
asf_var = 'thg_'+site+'_asf'
themis_calc_asf_glon_image_per_site, asf_var, crop=1
themis_asi_cal_brightness, glon_image_var, newname=glon_image_var+'_norm'
end
