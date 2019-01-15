;+
; Type: function.
; Purpose: Find filename from a fudge filename or pattern and epoch.
; Parameters:
;   in0, in, string, req. Can be a fudge filename contains wildcard * or ?.
;       Or can be a pattern, this way use epoch to determine filename.
;       See sptn2fn for format of pattern.
; Keywords:
;   et0s, in, double/dblarr[2]/string/strarr[2], opt. Epoch time or range.
;       Optional if in0 is not pattern, otherwise required. Can be string if
;       it's a valid input for stoepoch. Can be a time range spans several days.
;   all, in, boolean, opt. Default is to return highest version, set all
;       to return all filenames found.
; Return: string/strarr[n]. The filename(s) found.
; Notes: none.
; Dependence: slib.
; History:
;   2014-05-22, Sheng Tian, create.
;-

function sprepfn, in0, t = et0s, all = all

    ; in0 is fudge filename.
    fns = file_search(in0[0])
    if fns[0] ne '' then begin
        if keyword_set(all) then return, fns
        return, fns[n_elements(fns)-1]
    endif
    
    ; in0 is pattern.
    ptn = in0[0]            ; pattern.
    ets = stoepoch(et0s)    ; must have time info.
    if n_elements(ets) eq 2 then ets = sbreaktr(ets)
    nfn = n_elements(ets)*0.5>1
    tmp = strarr(nfn) & fns = ''
    for i = 0, nfn-1 do begin
        tmp[i] = sptn2fn(ptn, ets[0,i])
        tmp2 = file_search(tmp[i])
        if tmp2[0] eq '' then continue
        if ~keyword_set(all) then tmp2 = tmp2[n_elements(tmp2)-1]
        fns = [fns,tmp2]
    endfor
    nfn = n_elements(fns)
    if nfn eq 1 then message, 'no file found ...'
    return, fns[1:nfn-1]
end