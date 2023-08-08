;+
; NAME: 
;    madcompareversions(version1, version2)
;
; PURPOSE: 
;    Helper method that returns -1 if version1 less than version2, 0 if equal, 1 if greater
;
; INPUTS: 
;      version1 - list of integers in decreasing rank defining first version
;      version2 - list of integers in decreasing rank defining second version
;
; OUTPUT: true if version1 greater than equal to version2; false otherwise
; EXAMPLE: 
;     result = madcompareversions(version1, version2)
;
; $Id: madcompareversions.pro 6388 2017-12-20 21:58:45Z brideout $
;
FUNCTION madcompareversions, version1, version2

    result = 2
    for i=0, N_ELEMENTS(version1)-1 do begin
        if (N_ELEMENTS(version2)-1 ge i) then begin
            if (version1[i] gt version2[i]) then begin
                result = 1
                break
            endif
            if (version1[i] lt version2[i]) then begin
                result = -1
                break
            endif
        endif else begin
            result = -1
            break
        endelse
    endfor

    if (result eq 2) then begin
        if (N_ELEMENTS(version1) gt N_ELEMENTS(version2)) then begin
            result = -1
        endif else if (N_ELEMENTS(version1) lt N_ELEMENTS(version2)) then begin
            result = 1
        endif else begin
            result = 0
        endelse
    endif
	
    RETURN, result
END
