;+
; Return file_times in a given time range and site.
;
; input_time_range. Time range in unix time or string.
; site=. An input string to search with.
; id=. Can be 'l1%asf' or 'l1%ast'. By default is 'l1%asf'.
; urls. Output urls for data of the available sites.
;-


function themis_asi_read_available_file_times, input_time_range, site=site, id=datatype, errmsg=errmsg, urls=urls

    if n_elements(datatype) eq 0 then datatype = 'l1%asf'
    if n_elements(input_time_range) eq 0 then begin
        errmsg = 'No input time ...'
        return, !null
    endif

    if datatype eq 'l1%asf' then begin
        time_step = 3600d
    endif else if datatype eq 'l1%ast' then begin
        time_step = 86400d
    endif
    time_range = time_double(input_time_range)
    time_range = time_range-(time_range mod time_step)+[0,1]*time_step
    test_file_times = make_bins(time_range,time_step)
    test_time_range = minmax(test_file_times)
    

    file_request = themis_load_asi(test_time_range, site=site, id=datatype, return_request=1, version='v*')
    test_urls = apply_time_to_pattern(file_request.pattern.remote_file, test_file_times)
    
    file_times = list()
    urls = list()
    foreach url, test_urls, url_id do begin
        spd_download_expand, url, last_version=1, ssl_verify_peer=0, ssl_verify_host=0
        if url eq '' then continue
        file_times.add, test_file_times[url_id]
        urls.add, url
    endforeach
    file_times = file_times.toarray()
    urls = urls.toarray()
    

    return, file_times

end

time_range = time_double(['2015-03-12/07:00','2015-03-12/18:00'])
site = 'fykn'
file_times = themis_asi_read_available_file_times(time_range, site=site, id='l1%asf', urls=urls)
end