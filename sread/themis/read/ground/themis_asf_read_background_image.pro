;+
; Read ASF background image.
;-

function themis_asf_read_background_image, input_time_range, site=site, $
    errmsg=errmsg, get_name=get_name

    errmsg = ''
    retval = !null

    time_range = time_double(input_time_range)
    if n_elements(site) eq 0 then begin
        errmsg = 'No input site ...'
        return, retval
    endif

    asf_var = themis_read_asf(input_time_range, site=site, get_name=1)
    bg_var = asf_var+'_bg'
    if keyword_set(get_name) then return, bg_var
    files = themis_asf_load_background_image(input_time_range, site=site, errmsg=errmsg)
    if errmsg ne '' then return, retval


    var_list = list()

    var_list.add, dictionary($
        'in_vars', bg_var, $
        'time_var_name', 'unix_time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    get_data, bg_var, times, bg_1d
    ntime = n_elements(times)

    vatt = cdf_read_setting(bg_var, filename=files[0])
    image_size = vatt['image_size']
    npixel = product(image_size)
    bg = fltarr([ntime,npixel])

    center_index = cdf_read_var('center_index', filename=files[0])
    bg[*,center_index] = bg_1d
    bg = reform(bg, [ntime,image_size])
    store_data, bg_var, times, bg

    add_setting, bg_var, /smart, {$
        display_type: 'image', $
        image_size: image_size, $
        unit: 'Count', $
        short_name: strupcase(site[0])}

    return, bg_var


end

time_range = time_double(['2015-01-01/01:00','2015-01-01/02:00'])
site = 'atha'
asf_var = themis_read_asf(time_range, site=site)
bg_var = themis_asf_read_background_image(time_range, site=site)
get_data, asf_var, times, asf_images
get_data, bg_var, times, bg_images
cal_images = asf_images-bg_images
stop

sgopen, 0, size=[4,4]
foreach time, times, time_id do sgtv, bytscl(reform(cal_images[time_id,*,*]), min=-20000, max=20000, top=254), position=[0,0,1,1], ct=70

end