;+
; Read ASF raw iamge for one given site.
;
; input_time_range. Input time in string or unix time.
; site=. Required input, a string for site.
;-
pro themis_read_asf, input_time_range, site=site, errmsg=errmsg

    time_range = time_double(input_time_range)
    files = themis_load_asi(time_range, site=site, id='l1%asf', errmsg=errmsg)
    if errmsg ne '' then return

    var_list = list()

    asf_var = 'thg_'+site+'_asf'
    var_list.add, dictionary($
        'in_vars', 'thg_asf_'+site, $
        'out_vars', asf_var, $
        'time_var_name', 'thg_asf_'+site+'_time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return


    ; Read the raw image, convert it to float.
    get_data, asf_var, times, raw_images
    ntime = n_elements(times)
    if ntime eq 1 then raw_images = reform(raw_images, [1,size(raw_images,/dimensions)])
    raw_images = float(raw_images)  ; It's crucial to cast uint to float.
    image_size = size(reform(raw_images[0,*,*]),dimensions=1)
    
    ; Sometimes times are not uniform.
    time_step = 3
    common_times = make_bins(minmax(times),time_step, inner=1)
    ncommon_time = n_elements(common_times)
    if ncommon_time ne ntime then begin
        images = fltarr([ncommon_time,image_size])
        for ii=0,image_size[0]-1 do begin
            for jj=0,image_size[1]-1 do begin
                images[*,ii,jj] = interpol(raw_images[*,ii,jj],times, common_times)
            endfor
        endfor
        raw_images = temporary(images)
        times = temporary(common_times)
    endif

    ; Save the raw image.
    store_data, asf_var, times, raw_images
    add_setting, asf_var, /smart, {$
        display_type: 'image', $
        image_size: image_size, $
        unit: 'Count', $
        short_name: strupcase(site[0])}
        
    ; Read pixel and site info.
    pixel_info = themis_read_asi_pixel_info(time_range, site=site, id='asf')
    foreach key, pixel_info.keys() do begin
        options, asf_var, key, pixel_info[key]
    endforeach
    asc_info = themis_read_asi_site_info(site)
    foreach key, asc_info.keys() do begin
        options, asf_var, key, asc_info[key]
    endforeach

end

time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])   ; stable arc.
site = 'gako'

time_range = time_double(['2008-01-19/07:00','2008-01-19/08:00'])
site = 'kuuj'

time_range = time_double(['2019-03-28/08:00','2019-03-28/09:00'])
site = 'whit'

themis_read_asf, time_range, site=site
end
