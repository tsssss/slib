;+
; Type: procedure (internal).
;
; Purpose: Return norminal local and remote filenames. Basically string
;   operations, do not check file existence.
;
; Parameters:
;   tr0, in, double/string or dblarr[2]/strarr[2], optional. If in double or
;       string, set the time; if in dblarr[2] or strarr[2], set the time range.
;       For double or dblarr[2], it's the unix time or UTC. For string or
;       strarr[2], it's the formatted string accepted by stoepoch, e.g.,
;       'YYYY-MM-DD/hh:mm'.
;
; Keywords:
;   fn, in, string, optional. The full file name(s) includes explicit paths.
;   ptn, in, string, required. Required if file name is omitted, set the file
;       pattern contains format code for time to be replaced by real time.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   locfns, out, string, required. Local filenames.
;   remfns, out, string, required. Remote filenames.
;
; Notes: none.
;
; Dependence: slib.
;
; History:
;   2014-04-28, Sheng Tian, create.
;-
pro sprepfile0, tr0, fn = fn0, ptn = fnptn, dt = dt, $
    locfns = locfns, remfns = remfns, locroot = locroot, remroot = remroot

    if n_elements(remroot) eq 0 then remroot = ''
    
    ; fnptn, locroot, remroot, remroot, remptn must exist if fn0 is not set.
    nfn = n_elements(fn0)
    if nfn ne 0 then begin  ; file name is set, omit time range.
        locfns = fn0
        remfns = strarr(nfn)
        for i = 0, nfn-1 do begin
            locpath = file_dirname(locfns[i])
            if locpath eq '.' then begin    ; fn is base filename.
                remfns[i] = remroot+'/'+locfns[i]
                locfns[i] = locroot+'/'+locfns[i]
            endif else begin                ; fn includes path.
                idx = strpos(locfns[i], locroot)
                if idx ne 0 then message, 'conflicting local directories ...'
                remfns = remroot+strmid(locfns, strlen(locroot))
            endelse
        endfor
    endif else begin        ; find root directory & path & filename.
        ; deal with time.
        ntr = n_elements(tr0)
        if ntr eq 0 then message, 'no time info ...'
        if size(tr0,/type) eq 7 then tformat = '' else tformat = 'unix'
        etrs = stoepoch(tr0,tformat)
        if ntr eq 2 then etrs = sbreaktr(etrs, dt)
        
        ; path and filename.
        nfn = n_elements(etrs[0,*])
        locfns = strarr(nfn)
        remfns = strarr(nfn)
        for i = 0, nfn-1 do begin
            locfns[i] = sfmepoch(etrs[0,i],locroot+'/'+fnptn)
            remfns[i] = sfmepoch(etrs[0,i],remroot+'/'+fnptn)
        endfor
    endelse
    locfns = suniq(locfns)
    remfns = suniq(remfns)
end
