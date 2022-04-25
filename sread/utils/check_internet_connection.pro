;+
; Check internet connection for a given server.
;-

function check_internet_connection, url0, port=port, timeout=timeout

    server = (n_elements(url0) eq 0)? 'https://www.google.com': url0
    sep1 = '://'
    sep2 = '/'
    index = strpos(server, sep1)
    type = (index[0] eq -1)? 'http': strmid(server,0,index[0])
    server = (index[0] eq -1)? server: strmid(server,index[0]+strlen(sep1))
    index = strpos(server, sep2)
    server = (index[0] eq -1)? server: strmid(server,0,index[0])

;    if n_elements(port) eq 0 then port = 80
;    if n_elements(timeout) eq 0 then timeout = 0.5  ; sec.
;    socket, lun, server, port, /get_lun, error=error, connect_timeout=timeout
;    free_lun, lun
;    return, ~error

    url1 = type+sep1+server
    header = net_request_header(url1, status_code=status_code, timeout=timeout)
    if status_code ge 400 and status_code lt 500 then return, 0
    
    return, 1

end

print, check_internet_connection('https://cdaweb.gsfc.nasa.gov/pub/data/rbsp/rbspb/l1/efw/mscb1/2016/')
print, check_internet_connection('http://themis.ssl.berkeley.edu/data/themis/thg/l2/asi/cal')
print, check_internet_connection('https://themis.ssl.berkeley.edu/data/themis/thg/l2/asi/cal')
end
