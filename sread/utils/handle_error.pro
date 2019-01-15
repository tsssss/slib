;+
; Handle error in sread.
;-
;

function handle_error, msg, cdfid=cdfid, lun=lun, netcdfid=netcdfid

    errmsg = (n_elements(msg) eq 0)? '': msg
    lprmsg, errmsg
        
    ; close opened files.
    if n_elements(cdfid) ne 0 then foreach tid, cdfid do cdf_close, tid
    if n_elements(netcdfid) ne 0 then foreach tid, netcdfid do ncdf_close, tid
    if n_elements(lun) ne 0 then foreach tid, lun do free_lun, lun
    
    return, errmsg

end