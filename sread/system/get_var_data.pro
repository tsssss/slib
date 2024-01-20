;+
; Return data for a variable.
; 
; var. A string for tplot name.
; at=times. Set it to load the data at the given time or times.
; in=time_range. Set it to load the data at the given time range.
; raw=. A boolean. By default, the program shrinks unnecessary dimensions. Set raw to preserve all dimensions.
; times=. An array of times as output.
; limits=. A structure of options.
; settings=. A dictionary of options (essentially the same as limits but in dict).
;-
;
function get_var_data, var, val, in=time_range, at=time, raw=raw, times=times, limits=lim, settings=settings, _extra=ex

    retval = !null
    if n_elements(var) ne 1 then message, 'Invalid input var ...'   ; want to stop instead of return.
    if tnames(var) eq '' then return, retval
    
    get_data, var, data=info, limits=lim
    tags = strlowcase(tag_names(info))
    index = where(tags eq 'x', count)
    if count eq 0 then times = !null else times = info.(index)
    index = where(tags eq 'y', count)
    if count eq 0 then dat = !null else dat = info.(index)
    index = where(tags eq 'v', count)
    if count eq 0 then val = !null else val = info.(index)
    
    if size(lim,type=1) ne 8 then settings = !null else settings = dictionary(lim)
    
    if keyword_set(time) ne 0 then begin
        if n_elements(time) eq 1 then begin
            index = where(times eq time[0], count)
            if count eq 0 then dat = sinterpol(dat, times, time, /nan, _extra=ex) else dat = dat[index,*,*,*,*,*,*,*]
        endif else begin
            dat = sinterpol(dat, times, time, /nan, _extra=ex)
        endelse
    endif
    
    if n_elements(time_range) eq 2 then begin
        index = where_pro(times, time_range, count=count)
        if count eq 0 then return, retval
        dat = dat[index,*,*,*,*,*,*,*]
        times = times[index]
    endif
    
    if keyword_set(raw) then return, dat
    
    ; Shrink [1] to scalar.
    if n_elements(dat) eq 1 then return, dat[0]
    
    ; Shrink any useless dimension.
    return, reform(dat)
    
end