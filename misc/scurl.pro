;+
; Type: procedure.
; Purpose: Download any URL file/folder to local filename/directory.
; Parameters:
;   remfn, in, string, req. Remote URL. '' if URL is not found.
;   locfn, in, string, req. Local filename/directory.
; Keywords:
;   mtime, in/out, string/double, opt. In 'YYYYMMDDhhmm.ss...', in utc.
; Return: none.
; Notes: none.
; Dependence: none.
; History:
;   2015-02-20, Sheng Tian, create.
;-

; scurl uses curl in unix/linux, s_curl uses idl socket.
; the latter does not work for https links.

pro scurl, remfn, locfn
    
    console = -1
    printf, console, 'downloading '+remfn+' ...'

    locdir = file_dirname(locfn)
    if file_test(locdir,/directory) eq 0 then file_mkdir, locdir
    
    cmd = 'curl -o "'+locfn+'" -R "'+remfn+'"'

    spawn, cmd, msg, errmsg
    
    if errmsg[0] eq '' then begin
        printf, console, 'saved to '+locfn+' ...'   ; ok.
    endif else begin
        if !version.os_family ne 'Windows' then begin
            printf, console, strjoin(errmsg)    ; print errmsg in linux/unix.
        endif else begin
            tmp = strpos(errmsg,'is not recognized')
            ; when curl install in windows, 
            ; errmsg contains what should be in msg ...
            if tmp[0] eq -1 then begin
                print, console, 'saved to '+locfn+' ...'
            endif else begin
                print, console, errmsg
                print, console, 'install curl through cygwin in windows ...'
            endelse
        endelse        
    endelse

end

remfn = 'http://themis.ssl.berkeley.edu/data/themis/thg/l1/asi/fsmi/2013/05/thg_l1_ast_fsmi_20130501_v01.cdf'
remfn = 'http://themis.ssl.berkeley.edu/data/themis/thg/l1/asi/atha/2006/07/'
;remfn = 'http://themis.ssl.berkeley.edu/data/rbsp/rbspb/l1/vb1/2016/.remote-index.html'
locfn = shomedir()+'/idx.html'
;scurl, remfn, info = info
scurl, remfn, locfn
end