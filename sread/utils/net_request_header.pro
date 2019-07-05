;+
; Get the header of a URL. This is adopted from
; http://wiki.heliodocs.com/2014/08/02/sending-a-head-request-with-idlneturl/
; 
; url0. A string of URL.
; status_code. A number as output for the status code of the request.
; timeout. A number as input to specify the time out in second.
;-

function net_request_header_callback, status, progress

    ; Read header.
    ; progress[0] is 0 when there is no valid data.
    ; progress[2] is the total number of byte currently gotten.
    ; When header is done, we have a pause for getting data.
    if (progress[0] eq 1) && (progress[2] gt 0) then return, 0 else return, 1
    
end

function net_request_header, url0, status_code=status_code, timeout=timeout

;---Check input.
    if n_elements(url0) eq 0 then begin
        errmsg = handle_error('No input URL ...')
        return, ''
    endif
    
    url = url0[0]
    if size(url,/type) ne 7 then begin
        errmsg = handle_error('Input URL is not a string ...')
        return, ''
    endif
    
    ; remove the trailing '/', to get correct header for a folder.
    if strmid(url, 0,1, /reverse) eq '/' then url = strmid(url, 0,strlen(url)-1)
    
    ; the default value is somewhat long.
    ; I've tried 2 sec, doesn't work stably.
    if n_elements(timeout) eq 0 then timeout = 5.
    

;---Set callback function to stop after reading header.
    oo = obj_new('IDLnetURL')
    oo->setproperty, callback_function='net_request_header_callback'
    oo->setproperty, connect_timeout=timeout
    
    ; Read header until an error is caught.
    header = ''
    error = 0
    catch, error
    if error eq 0 then foo = oo->get(/buffer, url=url) else catch, /cancel
    
;---Get the header and status code.
    oo->getproperty, response_header=header
    oo->getproperty, response_code=status_code
    obj_destroy, oo
    
;    type = 'http'
;    sep1 = '://'
;    index = strpos(url, sep1)
;    type = (index[0] eq -1)? 'http': strmid(url,0,index[0])
;    case type of
;        'http': begin
;            header = strsplit(header, string(10b)+string(13b), /extract)
;            parts = stregex(header[0],'http[s]?/[0-9.]{3} ([0-9]{3}) [a-z]+',/subexp,/extract,/fold_case)
;            status_code = (parts[0] ne '')? fix(parts[1]): 404
;            end
;        'ftp': status_code = (header[0] eq '')? 404: 100
;        else: status_code = 404
;    endcase
    
    
    return, header
end


url = 'http://themis.ssl.berkeley.edu/data/rbsp/rbspb/l1/vb1/2015/'
url = 'http://themis.ssl.berkeley.edu/data/themis/tha/l2/efi/2014/tha_l2_efi_20140101_v01.cdf'
;url = 'https://satdat.ngdc.noaa.gov/sem/goes/data/'
;url = 'http://themis.ssl.berkeley.edu/data/rbsp/rbspb/l1/vb1/2015/rbspb_l1_vb1_20151219_v02.cdf'
;url = 'http://themis.ssl.berkeley.edu/data/themis/tha/l2/efi/2014/tha_l2_efi_20140101_v01.cdf'
headers = net_request_header(url, timeout=1)
foreach header, headers do print, header
end