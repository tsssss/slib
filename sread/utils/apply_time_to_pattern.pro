;+
; Apply ut times to a string of pattern.
; 
; pattern. A string containing unix time format code.
; times. An array of N times in ut time.
; return. An array of N strings after times are substituted.
;-
function apply_time_to_pattern, pattern, times
    
    ntime = n_elements(times)
    ; no pattern.
    if strpos(pattern,'%') eq -1 then return, replicate(pattern,ntime)
    
    res = strarr(ntime)
    for i=0, ntime-1 do begin
        res[i] = stodate(times[i], pattern)
    endfor
    
    return, res
end

times = sfmdate('2013-06-07/04:50', '%Y-%m-%d/%H:%M')
print, apply_time_to_pattern('rbspa_spice_products_%Y_%m%d_v01.cdf', times)
end