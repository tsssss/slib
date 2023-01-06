;+
; Map the old image to new image using the mapping info.
;-

function mlon_image_rect_map_old2new, old_images, site=site, crop=crop

    input_time_range = [0d,0]
    themis_read_asf_mlon_image_rect_read_mapping_info, input_time_range, site=site
    prefix = 'thg_'+site+'_mlon_image_rect_'

    old_image_size = get_var_data(prefix+'old_image_size')
    old_1d_size = product(old_image_size)
    nframe = n_elements(old_images)/old_1d_size

    reform_old_image = 1
    if nframe gt 1 then reform_old_image = 0
    if size(old_images, n_dimensions=1) eq 3 then reform_old_image = 0
    if reform_old_image then begin
        old_dims = size(old_images, dimensions=1)
        old_images = reform(old_images, [nframe,old_image_size])
    endif

    new_image_size = get_var_data(prefix+'new_image_size')
    new_1d_size = product(new_image_size)
    new_images = fltarr([nframe,new_image_size])

    new_uniq_pixels = get_var_data(prefix+'new_uniq_pixels')
    map_old2new = get_var_data(prefix+'map_old2new')
    map_old2new_uniq = get_var_data(prefix+'map_old2new_uniq')
    map_old2new_mult = get_var_data(prefix+'map_old2new_mult')

    ; one new -> one old.
    old_one = map_old2new[map_old2new_uniq].toarray()
    new_one = new_uniq_pixels[map_old2new_uniq]
    ; one new -> mult old.
    old_mult = map_old2new[map_old2new_mult]
    new_mult = new_uniq_pixels[map_old2new_mult]

    for time_id=0,nframe-1 do begin
        old_image = reform(old_images[time_id,*,*],old_1d_size)
        new_image = fltarr(new_1d_size)
        new_image[new_one] = old_image[old_one]
        foreach old_id, old_mult, new_id do begin
            val = old_image[old_id]
            val = median(val)
;            val = mean(val, nan=1)
            new_image[new_mult[new_id]] = val
        endforeach
        new_images[time_id,*,*] = reform(new_image, new_image_size)
    endfor

    if reform_old_image then old_images = reform(old_images, old_dims)
    if keyword_set(crop) then begin
        crop_xrange = get_var_data(prefix+'crop_xrange')
        crop_yrange = get_var_data(prefix+'crop_yrange')>0
        new_images = new_images[*,crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
    endif
    if nframe eq 1 then new_images = reform(new_images)
    return, new_images

end