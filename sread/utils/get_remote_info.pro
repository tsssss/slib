;+
; Return a structure of information on a given URL,
; including mtime in unix time, file size in byte.
;-
function get_remote_info, url0, errmsg=errmsg
    
    
;---Read header.
    header = net_request_header(url0, status_code=status_code)
    
    if status_code eq 404 then begin
        errmsg = handle_error('URL not found ...')
        return, {}
    endif
    
    ; filesize.
    idx = where(stregex(header,'Content-Length:') ne -1, cnt)
    fsize = cnt? ulong64(strmid(header[idx],strpos(header[idx],':')+1)): 0ull
    
    ; last modified time, in universal time.
    idx = where(stregex(header,'Last-Modified') ne -1, cnt)
    mtime0 = cnt? (strtrim(strmid(header[idx],strpos(header[idx],':')+1),2))[0]: ''
        
    ut0 = (mtime0 eq '')? 0d: sfmdate(mtime0,'%a, %d %b %Y %H:%M:%S %Z')
    info = {url:url0, mtime:ut0, size:fsize[0]}
    
    return, info
    
end

url = 'http://themis.ssl.berkeley.edu/data/rbsp/rbspb/l1/vb1/2015/'
url = 'http://themis.ssl.berkeley.edu/data/rbsp/rbspb/l1/vb1/2015/rbspb_l1_vb1_20151219_v02.cdf'
url = 'http://themis.ssl.berkeley.edu/data/themis/tha/l2/efi/2014/tha_l2_efi_20140101_v01.cdf'
info = get_remote_info(url)
end