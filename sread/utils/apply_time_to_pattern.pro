;+
; Apply times to a string containing the time format codes.
;
; pattern. A string containing the unix time format codes (%Y,%m,%d,etc).
; times. An array [N], times in UT sec.
; return. An array [N], strings with the times replaced.
;-
function apply_time_to_pattern, pattern, times
    retval = ''

    if n_elements(pattern) eq 0 then return, retval
    if typename(pattern) ne strupcase('string') then return, retval
    ntime = n_elements(times)
    if ntime eq 0 then return, pattern


    ; no pattern.
    if strpos(pattern,'%') eq -1 then return, replicate(pattern,ntime)

    res = strarr(ntime)
    for ii=0, ntime-1 do res[ii] = stodate(times[ii], pattern)

    return, res
end

times = sfmdate('2013-06-07/04:50', '%Y-%m-%d/%H:%M')
print, apply_time_to_pattern('rbspa_spice_products_%Y_%m%d_v01.cdf', times)
end
