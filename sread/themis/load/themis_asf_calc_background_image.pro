;+
; Load calibrated asf images.
;-

function themis_asf_calc_background_image, input_time_range, site=site, $
    asf_var=asf_var, errmsg=errmsg, output=bg_var, get_name=get_name, $
    min_bg_image=min_bg_image, test=test

    errmsg = ''
    retval = !null

;---Handle input.
    if n_elements(asf_var) eq 0 then begin
        time_range = time_double(input_time_range)
        asf_var = themis_read_asf(time_range, site=site, get_name=1)
        if check_if_update(asf_var, time_range) then begin
            asf_var = themis_read_asf(time_range, site=site)
            options, asf_var, 'requested_time_range', time_range
        endif
    endif else begin
        if n_elements(site) eq 0 then site = get_setting(asf_var, 'site')
        if n_elements(input_time_range) ne 2 then input_time_range = minmax(get_var_time(asf_var))
    endelse
    time_range = time_double(input_time_range)


;---Read original asf images.
    if n_elements(bg_var) eq 0 then bg_var = asf_var+'_bg'
    if keyword_set(get_name) then return, bg_var
    get_data, asf_var, times, orig_images, limits=lim
    image_size = lim.image_size
    npixel = product(image_size)
    nframe = n_elements(times)
    time_step = times[1]-times[0]


;---Seperate edge and center pixels.
    edge_indices = lim.edge_index
    center_index = lim.center_index


    bg_images = reform(orig_images, [nframe,npixel])
    foreach pixel, center_index do begin
        bg_images[*,pixel] = test_themis_asf_calc_background(bg_images[*,pixel])
    endforeach
    bg_images = reform(bg_images, [nframe,image_size])
    store_data, bg_var, times, bg_images, limits=lim
    options, bg_var, 'requested_time_range', time_range
    return, bg_var


end


time_range = time_double(['2016-10-13/04:10','2016-10-13/14:54'])   ; stable arc.
site = 'gako'
test = 1

bg_var = themis_asf_calc_background_image(time_range, site=site, test=test)

end