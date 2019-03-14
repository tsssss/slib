;+
; Make an array from a range and step. The array covers the range and is
; on interger multiples of the step. For example, for a range [0.5, 1.4] 
; and a step 1, the returned array is [0,1,2]. Similarly, for a range [0.5, 2],
; the returned array is [0,1,2].
; 
; dat0. Input array for the range or the actual data.
; step. A number for step.
; inner. A boolean. Set it to make the bins smaller than the range. Note 
;   that there is a risk of finding no bin when setting inner=1.
;-
;

function make_bins, dat0, step, inner=inner

    if step eq 0 then message, 'Step is 0 ...'
    step0 = abs(step)

    range0 = double([min(dat0,/nan),max(dat0,/nan)])
    range1 = range0-(range0 mod step0)
    if keyword_set(inner) then begin
        if range1[0] lt range0[0] then range1[0] += step0
        if range1[1] gt range0[1] then range1[1] -= step0
    endif else begin
        if range1[0] gt range0[0] then range1[0] -= step0
        if range1[1] lt range0[1] then range1[1] += step0
    endelse
    
    if range1[0] gt range1[1] then return, []
    if range1[0] eq range1[1] then return, [range1[0]]
    
    nbin = round((range1[1]-range1[0])/step0)   ; round b/c it may be 1.999.
    bins = range1[0] + findgen(nbin+1)*step0
    
    return, bins
end

print, make_bins([-53.2,-4.2], 10, /inner)
print, make_bins([0.5,1.4], 1)
print, make_bins([0.5,1.4], 1, /inner)
print, make_bins([0.5,2], -1)
end