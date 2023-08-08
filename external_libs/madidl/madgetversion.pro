;+
; NAME: 
;    madgetversion(madurl)
;
; PURPOSE: 
;    Get information on version at the Madrigal site specified
;    by madUrl
;
; INPUTS: 
;      madurl - scalar string giving a fully qualified url to the Madrigal site
;
; OUTPUT: a list of integers giving version in descending order (eg, [2 6 4])
; EXAMPLE: 
;     result = madgetversion('http://millstonehill.haystack.mit.edu')
;
; $Id: madgetversion.pro 6810 2019-03-28 19:01:24Z brideout $
;
FUNCTION madgetversion, madurl

    scriptName = 'getVersionService.py'
    
    ; determine if needed parameters set
    if (n_params() lt 1) then begin
        message, 'Too few parameters specified - see usage in madgetversion.pro'
    endif
    
    ; get cgiUrl
    cgiUrl = madgetcgiurl(madurl)
    
    instUrl = cgiUrl + scriptName ; no arguments needed
    
    ; try wget
    wgetCmd = 'wget -q -O idl_temp_file.txt "' + instUrl + '"'
    spawn, wgetCmd, listing, EXIT_STATUS=error
    
    ; see if wget worked
    error = STRCOMPRESS(error, /REMOVE_ALL)
    if (error NE 0) then begin
        message, 'got error <' + error + '> - perhaps you need to install wget?'
    endif

    nlines = FILE_LINES('idl_temp_file.txt')

    lines = STRARR(nLines)

    OPENR, inunit, 'idl_temp_file.txt', /GET_LUN
    READF, inunit, lines
    FREE_LUN, inunit
    FILE_DELETE, 'idl_temp_file.txt',  /ALLOW_NONEXISTENT,  /QUIET
    
    for i=0, N_ELEMENTS(lines)-1 do begin
        words = strsplit(lines[i], '.', /EXTRACT, /PRESERVE_NULL)
        if (N_ELEMENTS(words) LT 2) then continue
        break
    endfor
    
    

    version = intarr(N_ELEMENTS(words))
    for i=0, N_ELEMENTS(words)-1 do begin
        version[i] = long(words[i])
    endfor
    
	
	RETURN, version
END
