;+
; Read GLon image per site (with calibrated brightness).
;-
pro themis_asf_read_glon_image_per_site, input_time_range, site=site, thumbnail=thumbnail, errmsg=errmsg

    errmsg = ''
    datatype = 'asf'
    if keyword_set(thumbnail) then datatype = 'ast'
    time_range = time_double(input_time_range)

    files = themis_asf_load_glon_image_per_site(time_range, site=site, errmsg=errmsg)
    if errmsg ne '' then return

    var_list = list()

    glon_image_var = 'thg_'+site+'_glon_image'
    var_list.add, dictionary($
        'in_vars', glon_image_var, $
        'time_var_name', 'time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return

    vars = ['pixel_'+['glon','glat','elev','azim','xpos','ypos'], $
        'crop_'+['xrange','yrange'], 'image_'+['pos','size']]
    settings = dictionary($
        'display_type', 'image', $
        'unit', 'Count #' )
    foreach var, vars do begin
        settings[var] = cdf_read_var(var, filename=files[0])
    endforeach
    add_setting, glon_image_var, smart=1, settings

end


input_time_range = time_double(['2013-03-17/05:00','2013-03-17/06:00'])
site = 'mcgr'
themis_asf_read_glon_image_per_site, input_time_range, site=site
end
