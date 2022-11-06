;+
; Return sites have data for a given time.
; 
; input_time. Time in unix time or string.
; sites=. An input array to search with. By default is to search all sites.
; id=. Can be 'l1%asf' or 'l1%ast'. By default is 'l1%asf'.
; urls. Output urls for data of the available sites.
;-

function themis_read_asi_available_sites, input_time, sites=sites, id=datatype, errmsg=errmsg, urls=urls

    if n_elements(sites) eq 0 then sites = themis_read_asi_sites()
    if n_elements(datatype) eq 0 then datatype = 'l1%asf'
    if n_elements(input_time) eq 0 then begin
        errmsg = 'No input time ...'
        return, !null
    endif
    time = time_double(input_time[0])
    urls = list()
    avail_sites = list()
    foreach site, sites do begin
        file_request = themis_load_asi(time, site=site, id=datatype, return_request=1, version='v*')
        url = apply_time_to_pattern(file_request.pattern.remote_file, time)
        spd_download_expand, url, last_version=1, $
            ssl_verify_peer=0, ssl_verify_host=0
        if url eq '' then continue
        avail_sites.add, site
        urls.add, url
    endforeach
    urls = urls.toarray()
    avail_sites = avail_sites.toarray()

    return, avail_sites

end

time = time_double('2008-01-24/05:00')
sites = themis_read_asi_available_sites(time, id='l1%ast', urls=urls)
end