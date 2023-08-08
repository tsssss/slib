;+
; NAME: 
;    madgetcgiurl(madurl)
;
; PURPOSE: 
;    Get the Madrigal CGI url based on the base Madrigal url.  This is meant
;    to be a private method used internal by other methods.
;
; INPUTS: 
;      madurl - scalar string giving a fully qualified url to the base Madrigal site
;
; OUTPUT: a string giving the base Madrigal CGI url
; EXAMPLE: 
;      result = madgetcgiurl('http://millstonehill.haystack.mit.edu')
;
; $Id: madgetcgiurl.pro 6810 2019-03-28 19:01:24Z brideout $
;
FUNCTION madgetcgiurl, madurl
	
	; constants
	cgiName = 'accessData.cgi'
	
	; determine if needed parameters set
  if (n_params() lt 1) then begin
      message, 'Too few parameters specified - see usage in madgetcgiurl.pro'
  endif
	
	; make sure url ends /
        lastChar = strmid(madurl, strlen(madurl)-1)
        if (lastChar ne '/') then begin
            madurl += '/'
        endif
	
	; make sure url starts with http
	result = stregex(madurl, 'http://', /BOOLEAN)
	if (~ result) then begin
		message, 'madurl must start with http://'
	endif
	
	; get the rootUrl
	index = strpos(madurl, '/', 8) ; 8 is to skip http://? part
	rootUrl = strmid(madurl, 0, index)
	
	; try wget
	wgetCmd = 'wget -q -O idl_temp_file.txt "' + madurl + '"'
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

	regex = '".*' + cgiName
	cgiUrlList = stregex(lines, regex, /EXTRACT)
	
	; find the first non-zero length string
	cgiUrl = ""
	for i=0, N_ELEMENTS(cgiUrlList)-1 do begin
	    if (strlen(cgiUrlList[i]) gt strlen(cgiName)) then begin
	        cgiUrl = cgiUrlList[i]
	        break
	    endif
	endfor
	
	if (strlen(cgiUrl) eq 0) then begin
		message, 'error parsing home page'
	endif
	
	index1 = strpos(cgiUrl, '"')
	index2 = strpos(cgiUrl, cgiName)
	baseUrl = strmid(cgiUrl, index1+1, index2-(index1+1))
	
	retStr =rootUrl + baseUrl
	RETURN, retStr
END
