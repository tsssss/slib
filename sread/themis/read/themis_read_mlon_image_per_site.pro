;+
; Read MLon image per site (with calibrated brightness).
;-
pro themis_read_mlon_image_per_site, input_time_range, site=site, thumbnail=thumbnail, errmsg=errmsg

    errmsg = ''
    datatype = 'asf'
    if keyword_set(thumbnail) then datatype = 'ast'
    time_range = time_double(input_time_range)

    files = themis_load_asf_mlon_image_per_site(time_range, site=site, errmsg=errmsg)
    if errmsg ne '' then return

    var_list = list()

    mlon_image_var = 'thg_'+site+'_mlon_image'
    var_list.add, dictionary($
        'in_vars', mlon_image_var, $
        'time_var_name', 'time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return
    get_data, mlon_image_var, times, images
    images = transpose(images,[0,2,1])
    store_data, mlon_image_var, times, images
    

    vars = ['pixel_'+['mlon','mlat','elev','azim','xpos','ypos'], $
        'crop_'+['xrange','yrange'], 'image_'+['pos','size']]
    settings = dictionary($
        'display_type', 'image', $
        'unit', 'Count #' )
    foreach var, vars do begin
        settings[var] = cdf_read_var(var, filename=files[0])
    endforeach
    add_setting, mlon_image_var, smart=1, settings

end


input_time_range = time_double(['2013-03-17/05:00','2013-03-17/06:00'])
site = 'mcgr'
themis_read_mlon_image_per_site, input_time_range, site=site
end
