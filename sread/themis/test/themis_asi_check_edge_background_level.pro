;+
; Check the background level for a certain site over one day.
;-

function themis_asi_check_edge_background_level, input_time_range, site=site

    retval = !null
    if n_elements(site) eq 0 then return, retval

;---Get the time range and date.
    secofday = constant('secofday')
    time_range = time_double(input_time_range)
    date = time_range[0]-(time_range[0] mod secofday)
    time_range = date+[0,secofday]
    secofhour = constant('secofhour')

;---Check for all sites for data availability.
    file_times = make_bins(time_range+[0,-1]*secofhour,secofhour)
    site_info = themis_asi_read_site_info(site)
    midn_ut = date+site_info['midn_ut']
    search_time_range = midn_ut+[-1,1]*9*secofhour
    file_times = themis_asi_read_available_file_times(search_time_range, site=site)
    nfile_time = n_elements(file_times)
    if nfile_time eq 0 then return, retval
        
    fillval = !values.f_nan
    bg_levels = fltarr(nfile_time)+fillval
    bg_mins = fltarr(nfile_time)+fillval
    foreach file_time, file_times, file_id do begin
        the_time_range = file_time+[0,secofhour]
        asf_var = themis_read_asf(the_time_range, site=site)
        get_data, asf_var, times, asf_images, limits=lim
        ntime = n_elements(times)
        image_size = double(lim.image_size)
        asf_images_1d = reform(asf_images, [ntime,image_size])

        pixel_elevs = lim.pixel_elev
        pixel_azims = lim.pixel_azim
        edge_indices = where(finite(pixel_elevs,nan=1) or pixel_elevs le 0, nedge_index)
        if nedge_index eq 0 then continue

        bg_levels[file_id] = median(asf_images_1d[*,edge_indices])
        bg_mins[file_id] = min(asf_images_1d[*,edge_indices])
    endforeach

    bg_var = 'thg_asf_'+site+'_edge_bg'
    store_data, bg_var, file_times, [[bg_levels],[bg_mins]]
    add_setting, bg_var, smart=1, dictionary($
        'display_type', 'stack', $
        'unit', '#', $
        'labels', ['Median','Min'], $
        'colors', sgcolor(['blue','red']), $
        'ylog', 1, $
        'yrange', [1e3,1e5] )
    return, bg_var

end


date = '2008-01-19'
sites = themis_read_asi_sites()
foreach site, sites do tmp = themis_asi_check_edge_background_level(date, site=site)
end