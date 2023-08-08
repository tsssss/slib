;+
; NAME: 
;    madgetallinstruments(madurl)
;
; PURPOSE: 
;    Get information on all instruments with data at the Madrigal site specified
;    by madUrl
;
; INPUTS: 
;      madurl - scalar string giving a fully qualified url to the Madrigal site
;
; OUTPUT: an array of structures with the following fields:
;		1. name - (string) Example: 'Millstone Hill Incoherent Scatter Radar'
;		2. code - (int) Example: 30
;		3. mnemonic - (3 char string) Example: 'mlh'
;		4. latitude - (double) Example: 45.0
;		5. longitude (double) Example: 110.0
;		6. altitude (double)  Example: 0.015 (km)
;		7. category (string) Example: 'Incoherent scatter radars'
; EXAMPLE: 
;     result = madGetAllInstruments('http://millstonehill.haystack.mit.edu')
;
; $Id: madgetallinstruments.pro 6810 2019-03-28 19:01:24Z brideout $
;
FUNCTION madgetallinstruments, madurl

    scriptName = 'getInstrumentsService.py'
    
    ; determine if needed parameters set
  if (n_params() lt 1) then begin
      message, 'Too few parameters specified - see usage in madgetallinstruments.pro'
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
    
    ; this first pass through the data is simply to get a count
    totalLines = 0
    for i=0, N_ELEMENTS(lines)-1 do begin
        words = strsplit(lines[i], ',', /EXTRACT, /PRESERVE_NULL)
        if (N_ELEMENTS(words) LT 6) then continue
        totalLines += 1
    endfor
    
    ; create default instArr
    instDefault = {name:"", code:0, mnemonic:"", latitude:0.0, longitude:0.0, altitude:0.0, category:'unknown'} 
    instArr = REPLICATE(instDefault, totalLines) 
    
    ; this pass fills out that array
    index = 0
    for i=0, N_ELEMENTS(lines)-1 do begin
        words = strsplit(lines[i], ',', /EXTRACT, /PRESERVE_NULL)
        if (N_ELEMENTS(words) LT 6) then continue
        instArr[index].name = words[0]
        instArr[index].code = uint(words[1])
        instArr[index].mnemonic = words[2]
        instArr[index].latitude = double(words[3])
        instArr[index].longitude = double(words[4])
        instArr[index].altitude = double(words[5])
        if (N_ELEMENTS(words) GT 6) then begin
            instArr[index].category = words[6]
        endif else begin
            instArr[index].category = 'unknown'
        endelse
        index += 1
    endfor
	
	RETURN, instArr
END
