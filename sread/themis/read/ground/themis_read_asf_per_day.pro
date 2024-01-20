function themis_read_asf_per_day, input_time_range

;---Determine the date.
    secofday = constant('secofday')
    time_range = time_double(input_time_range)
    date = time_range[0]-(time_range[0] mod secofday)
    time_range = date+[0,secofday]
    secofhour = constant('secofhour')

;---Check for all sites for data availability.
; Note: sometimes themis summary plot shows asf has data, but cdfs are not available.
; e.g., mcgr on 2015-01-01/
    all_sites = themis_read_asi_sites()
    avail_info = orderedhash()
    file_times = make_bins(time_range+[0,-1]*secofhour,secofhour)
    foreach site, all_sites do begin
        site_info = themis_asi_read_site_info(site)
        midn_ut = date+site_info['midn_ut']
        search_time_range = midn_ut+[-1,1]*9*secofhour
        file_times = themis_asi_read_available_file_times(search_time_range, site=site)
        nfile_time = n_elements(file_times)
        if nfile_time eq 0 then continue
        
        avail_info[site] = file_times
    endforeach
    avail_sites = (avail_info.keys()).toarray()
    navail_site = n_elements(avail_sites)

;    foreach site, avail_sites do begin
;        print, site+'    '+strjoin(time_string(minmax(avail_info[site])), ' to ')
;    endforeach
    
    
;---Get the exact start and end times for each site.
    site_time_ranges = orderedhash()
    foreach site, avail_sites do begin
        file_times = avail_info[site]
        asf_var = themis_read_asf(min(file_times)+[0,secofhour], site=site)
        get_data, asf_var, times
        start_time = min(times)
        asf_var = themis_read_asf(max(file_times)+[0,secofhour], site=site)
        get_data, asf_var, times
        end_time = max(times)
        site_time_ranges[site] = [start_time,end_time]
    endforeach
    
;    foreach site, avail_sites do begin
;        print, site+'    '+strjoin(time_string(site_time_ranges[site]), ' to ')
;    endforeach
    
    
;---Load data and check for cloud for each site.
    foreach site, avail_sites do begin
        if site ne 'talo' then continue
        asf_var = themis_read_asf(site_time_ranges[site], site=site)
        get_data, asf_var, times, asf_images
        stop
    endforeach
    ;data_time_range = minmax((site_time_ranges.values()).toarray())
    
stop

end


tmp = themis_read_asf_per_day('2015-01-01')
end