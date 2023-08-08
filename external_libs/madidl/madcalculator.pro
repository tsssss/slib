;+
; NAME: 
;    madcalculator(madurl, year,  month, day, hour, min, sec, startLat, endLat, stepLat,
;                             startLong, endLong, stepLong, startAlt, endAlt, stepAlt,  parms)
;
; PURPOSE: 
;    madcalculator calculates requested derived parameter for a given time and grid of spatial points
;
; INPUTS: 
;      madurl - scalar string giving a fully qualified url to the Madrigal site
;      year,  month, day, hour, min, sec - time at which to run calculation
;      startLat - Starting geodetic latitude, -90 to 90 (float)
;      endLat - Ending geodetic latitude, -90 to 90 (float)
;      stepLat - Latitude step (0.1 to 90) (float)
;      startLong - Starting geodetic longitude, -180 to 180  (float)
;      endLong - Ending geodetic longitude, -180 to 180 (float)
;      stepLong - Longitude step (0.1 to 180) (float)
;      startAlt - Starting geodetic altitude, >= 0 (float)
;      endAlt - Ending geodetic altitude, > 0 (float)
;      stepAlt - Altitude step (>= 0.1) (float)
;      parms - comma delimited string of Madrigal parameters desired
;
; OUTPUT: a two dimensional array of doubles.  Number of columns = 3 + number of parameters requested, because the
;                first three parameters are always geodetic latitude, longitude, and altitude.  Number of rows
;                is the number of latitudes * number of longitudes * number of altitudes.
; EXAMPLE: 
;     result = madcalculator(1999,2,15,12,30,0,45,55,5,-170,-150,10,200,200,0,'bmag,bn')
;
; $Id: madcalculator.pro 6974 2019-07-29 19:55:06Z brideout $
;
FUNCTION madcalculator, madurl, year,  month, day, hour, min, sec, startLat, endLat, stepLat,  $
                       startLong, endLong, stepLong, startAlt, endAlt, stepAlt,  parms

    scriptName = 'madCalculatorService.py'
    
    ; determine if needed parameters set
    if (n_params() lt 17) then begin
      message, 'Too few parameters specified - see usage in madcalculator.pro'
    endif
    
    ; get cgiUrl
    cgiUrl = madgetcgiurl(madurl)
    
    result = strmatch(parms, '* *')
    if (result eq 1) then begin
        message, 'parms string must not contain spaces'
    endif
    
    ; get numParms
    parmList = strsplit(parms, ',', /EXTRACT, /PRESERVE_NULL)
    numParms = n_elements(parmList)
    if (strlen(parmList[0]) eq 0) then begin
         message, 'At least one parameter must be specified'
    endif
    
    ; build url
    expUrl = cgiUrl + scriptName + '?'
    ; append times
    expUrl += string(format='(%"year=%i&")', year)
    expUrl += string(format='(%"month=%i&")', month)
    expUrl += string(format='(%"day=%i&")', day)
    expUrl += string(format='(%"hour=%i&")', hour)
    expUrl += string(format='(%"min=%i&")', min)
    expUrl += string(format='(%"sec=%i&")', sec)
    expUrl += string(format='(%"startLat=%f&")', startLat)
    expUrl += string(format='(%"endLat=%f&")', endLat)
    expUrl += string(format='(%"stepLat=%f&")', stepLat)
    expUrl += string(format='(%"startLong=%f&")', startLong)
    expUrl += string(format='(%"endLong=%f&")', endLong)
    expUrl += string(format='(%"stepLong=%f&")', stepLong)
    expUrl += string(format='(%"startAlt=%f&")', startAlt)
    expUrl += string(format='(%"endAlt=%f&")', endAlt)
    expUrl += string(format='(%"stepAlt=%f&")', stepAlt)
    parms2 = String(Replicate(32B, strlen(parms)))
    strput, parms2, parms
    strreplaceall, parms2, '+', '%2B'
    expUrl += string(format='(%"parms=%s")', parms2)
    
    ; try wget
    wgetCmd = 'wget -q --timeout=600 --tries=4 -O idl_temp_file.txt "' + expUrl + '"'
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
        words = strsplit(lines[i], ' ', /EXTRACT)
        ; check for an error message in the first few lines
        if (i lt 10 and N_ELEMENTS(words) gt 1) then begin
            for j=0, N_ELEMENTS(words)-1 do begin
                ; skip assumed, missing, knownbad
                if (strcmp(strlowcase(words[j]), 'missing') eq 1) then continue
                if (strcmp(strlowcase(words[j]), 'assumed') eq 1) then continue
                if (strcmp(strlowcase(words[j]), 'knownbad') eq 1) then continue
                if (num_chk(words[j]) eq 1) then begin
                    print, 'Error: ', lines
                    message, 'Error: ' + lines[i]
                endif
            endfor
        endif
        if (N_ELEMENTS(words) LT numParms + 3) then continue
        totalLines += 1
    endfor
    
    if (totalLines eq 0) then begin
        return, ptr_new()
    endif
    
    ; create dataArr set to all zeros
    dataArr = fltarr(numParms + 3, totalLines)
    
    ; this pass fills out that array
    index = 0
    for i=0, N_ELEMENTS(lines)-1 do begin
        words = strsplit(lines[i], ' ', /EXTRACT)
        if (N_ELEMENTS(words) LT numParms + 3) then continue
        ; loop through each parm
        for j=0, numParms + 2 do begin
            ; set all missing, assumed, and knownbad to NaN
            if (strcmp(strlowcase(words[j]), 'missing') eq 1 or $
                 strcmp(strlowcase(words[j]), 'assumed') eq 1 or $
                 strcmp(strlowcase(words[j]), 'knownbad') eq 1) then begin
                 dataArr[j,index] = !values.F_NAN
            endif else begin
                if (num_chk(words[j]) eq 1 ) then begin
                    dataArr[j,index] = !values.F_NAN
                endif else begin
                    dataArr[j,index] = float(words[j])
                endelse
            endelse
        endfor
        index += 1
    endfor
    
  RETURN, dataArr
END
