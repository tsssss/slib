;+
; Function: sdatarate.
; Purpose: Get data rate of a time series.
; Parameters:
;   t0s, in, dblarr(n), req. Time series in sec (e.g., unix time).
; Keywords: none.
; Return: out, double. Data rate in sec.
; Notes: The input time series needs to be quasi-uniform, but can has gaps.
; Dependence: slib.
; History:
;   2012-09-28, Sheng Tian, create.
;   2018-12-12, Sehng Tian, use median if not monotonic.
;-

function sdatarate, t0s
  
    compile_opt idl2
    on_error, 2
  
    ; uniq.
    t1s = suniq(t0s)
  
    nrec = n_elements(t1s)
    if nrec le 1 then begin
        message, 'time series is too short ...', /continue
        return, 0
    endif else if nrec eq 2 then return, t1s[1]-t1s[0]
  
    ; get difference.
    diff = t1s[1:nrec-1]-t1s[0:nrec-2]
  
    ; check monotonically increase.
    idx = where(diff lt 0d)
    if idx[0] ne -1 then begin
        message, 'time series is not monotonically increasing ...', /continue
        return, median(diff)
    endif
    
    ; compute predominant data rate.
    minrate = min(diff)
    rate = mean(diff[where(diff lt minrate*1.2)])
    return, rate

end
