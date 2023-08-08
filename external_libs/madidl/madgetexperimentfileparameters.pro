;+
; NAME: 
;    madgetexperimentfileparameters(madurl, fullFilename)
;
; PURPOSE: 
;    returns a list of all measured and derivable parameters in file
;
; INPUTS: 
;      madurl - scalar string giving a fully qualified url to the Madrigal site
;      fullFilename - full path to experiment file as returned by madGetExperimentFiles.
;
; OUTPUT: an array of structures representing parameters for that experiment file with the following fields:
;     1. mnemonic (string) Example 'dti'
;     2. description (string) Example: "F10.7 Multiday average observed (Ott)"
;     3. isError (int) 1 if error parameter, 0 if not
;     4. units (string) Example "W/m2/Hz"
;     5. isMeasured (int) 1 if measured, 0 if derivable
;     6. category (string) Example: "Time Related Parameter"
;     7. isSure (int)  1 if parameter can be found for every record, 0 if can only be found for some
;     8. isAddIncrement - 1 if additional increment, 0 if normal, -1 if unknown (this capability
;                        only added with Madrigal 2.5)
; EXAMPLE: 
;     result = madGetExperimentFileParameters('http://millstonehill.haystack.mit.edu', '/opt/madrigal/blah/mlh980120g.001')
;
; $Id: madgetexperimentfileparameters.pro 6810 2019-03-28 19:01:24Z brideout $
;
FUNCTION madGetExperimentFileParameters, madurl,  fullFilename

    scriptName = 'getParametersService.py'
    
    ; determine if needed parameters set
    if (n_params() lt 2) then begin
      message, 'Too few parameters specified - see usage in madgetexperimentfileparameters.pro'
    endif
    
    ; get cgiUrl
    cgiUrl = madgetcgiurl(madurl)
    
    ; now call the main method to get parameters
    expUrl = cgiUrl + scriptName + '?'
    expUrl += string(format='(%"filename=%s")', fullFilename)

    ; try wget
    wgetCmd = 'wget -q -O idl_temp_file.txt "' + expUrl + '"'
    spawn, wgetCmd, listing, EXIT_STATUS=error
    
    ; see if wget worked
    error = STRCOMPRESS(error, /REMOVE_ALL)
    if (error NE 0) then begin
        message, 'got error <' + error + '> - perhaps you need to install wget?'
    endif

    nlines = FILE_LINES('idl_temp_file.txt')
    
    if (nlines ne 0) then begin
        ; raise exception
    ;    message, 'Error: No parameters returned for fullFilename ' + fullFilename ; --- See David Section
    ;endif  ; --- See David Section

    lines = STRARR(nLines)

    OPENR, inunit, 'idl_temp_file.txt', /GET_LUN
    READF, inunit, lines
    FREE_LUN, inunit
    FILE_DELETE, 'idl_temp_file.txt',  /ALLOW_NONEXISTENT,  /QUIET
    
    ; this first pass through the data is simply to get a count
    totalLines = 0
    for i=0, N_ELEMENTS(lines)-1 do begin
        words = strsplit(lines[i], '\', /EXTRACT, /PRESERVE_NULL)
        if (N_ELEMENTS(words) LT 7) then begin
            continue
        endif 
        totalLines += 1
    endfor
    
    if (totalLines eq 0) then begin
        ; raise exception
        message, 'Error: No parameters returned for fullFilename ' + fullFilename
    endif
    
    ; create default parmArr
    parmDefault = {mnemonic:"", description:"", iserror:0, units:"", ismeasured:0, category:"",issure:0,isaddincrement:0} 
    parmArr = REPLICATE(parmDefault, totalLines) 
    
    ; this pass fills out that array
    index = 0
    for i=0, N_ELEMENTS(lines)-1 do begin
        words = strsplit(lines[i], '\', /EXTRACT, /PRESERVE_NULL)
        if (N_ELEMENTS(words) LT 7) then begin
            continue
        endif 
        parmArr[index].mnemonic = words[0]
        parmArr[index].description = words[1]
        parmArr[index].iserror = uint(words[2])
        parmArr[index].units = words[3]
        parmArr[index].ismeasured = uint(words[4])
        parmArr[index].category = words[5]
        parmArr[index].issure = uint(words[6])
        if (N_ELEMENTS(words) gt 7) then begin
            parmArr[index].isaddincrement = uint(words[7])
        endif else begin
            parmArr[index].isaddincrement = -1
        endelse
	index += 1
    endfor
    
    
    endif else begin; --- David Section
    parmDefault = {mnemonic:"", description:"", iserror:0, units:"", ismeasured:0, category:"",issure:0,isaddincrement:0} 
    parmArr = REPLICATE(parmDefault, 1) ; Probably don't need the replicate here but I'm just leaving it until I make sure things are functional.
    parmArr[0].mnemonic = "NO_DATA" ; Not the greatest way to do this, but it should work.
    print, 'Error: No parameters returned for fullFilename ' + fullFilename
    endelse
    
	RETURN, parmArr
END
