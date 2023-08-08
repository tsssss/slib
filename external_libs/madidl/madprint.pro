;+
; NAME: 
;    madprint(madurl, fullFilename, parms, filters, user_fullname, user_email, user_affiliation, ignore_no_data, verbose, outputFile)
;
; PURPOSE: 
;    madPrint returns a two-dimensional array of doubles based on user-specified parmeters and filters.
;
;       See madSimplePrint to print a file with all data and just those parameters in the file itself.
;
;        madPrint allows you to choose which parameters to print, to print derived parameters, or
;        to filter the data.
;
; INPUTS: 
;      madurl - scalar string giving a fully qualified url to the Madrigal site
;      fullFilename - full path to experiment file as returned by madGetExperimentFiles.
;      parms - Comma delimited string listing requested parameters (no spaces allowed).
;      filters - Space delimited string listing filters desired, as in isprint command (see
;                   Documentation->Administrator's Guide->Using isprint for file quick looks)
;      user_fullname - full name of user making request
;      user_email - email address of user making request
;      user_affiliation - affiliation of user making request
;      ignore_no_data - if 0 (the default), raises error if no data, If 1, ignores no data
;      verbose - if 0 (the default) no printing progress information.  If 1, print progress information.
;      outputFile - if not '', download the results to outputFile.  If outputFile has an extension
;                of .h5, .hdf, or .hdf5, will download in Madrigal Hdf5 format.  If it has a .nc extension, will
;                download as netCDF4. Otherwise, it will download as column delimited ascii.
;                Trying to save as Hdf5 or netCDF4 with a Madrigal 2 site will raise an exception
;                If '' (the default) parse data into array.
;
; OUTPUT:  If outputFile is '', returns a two dimensional array of doubles.  Number of columns = number of parameters requested.  Number of rows
;         is the number of measurments.  Note that Madrigal often contains a number a measurments at the same time
;         (such as when a radar makes different range measurements at the same time), so two or more rows may have the same time.
;         If outputFile not '', saves data into file, and returns 1.  If error on server, prints error and returns -1
; EXAMPLE: 
;     result = madPrint('http://millstonehill.haystack.mit.edu', '/opt/madrigal/blah/mlh980120g.001', $
;                                   'year,month,day,hour,min,sec,gdalt,ti', 'filter=gdalt,500,600 filter=ti,1900,2000' $
;                                   'Bill Rideout', 'brideout@haystack.mit.edu', 'MIT')
;
; $Id: madprint.pro 6974 2019-07-29 19:55:06Z brideout $
;
FUNCTION madPrint, madurl,  fullFilename, parms, filters, user_fullname, user_email, user_affiliation, ignore_no_data, $
    verbose, outputFile

    scriptName = 'isprintService.py'
    
    ; determine if needed parameters set
    if (n_params() lt 7) then begin
      message, 'Too few parameters specified - see usage in madprint.pro'
    endif
    
    ; set ignore_no_data if needed
    if (n_params() lt 8) then begin
      ignore_no_data = 0
    endif

    ; set verbose if needed
    if (n_params() lt 9) then begin
      verbose = 0
    endif

    ; set verbose if needed
    if (n_params() lt 10) then begin
      outputFile = ''
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
    fullFilename2 = String(Replicate(32B, strlen(fullFilename)))
    strput, fullFilename2, fullFilename
    strreplaceall, fullFilename2, '/',  '%2F'
    expUrl += string(format='(%"file=%s&")', fullFilename2)
    parms2 = String(Replicate(32B, strlen(parms)))
    strput, parms2, parms
    strreplaceall, parms2, '+', '%2B'
    strreplaceall, parms2, ',', '+'
    expUrl += string(format='(%"parms=%s&")', parms2)
    if (strlen(filters) gt 0) then begin
        filters2 = String(Replicate(32B, strlen(filters)))
    endif else begin
        filters2 = ''
    endelse
    strput, filters2, filters
    strreplaceall, filters2, '=', '%3D'
    strreplaceall, filters2, ',', '%2C'
    strreplaceall, filters2, '/', '%2F'
    strreplaceall, filters2, '+', '%2B'
    strreplaceall, filters2, ' ', '+'
    expUrl += string(format='(%"filters=%s&")', filters2)
    user_fullname2 = String(Replicate(32B, strlen(user_fullname)))
    strput, user_fullname2, user_fullname
    strreplaceall, user_fullname2, ' ', '+'
    expUrl += string(format='(%"user_fullname=%s&")', user_fullname2)
    user_email2 = String(Replicate(32B, strlen(user_email)))
    strput, user_email2, user_email
    strreplaceall, user_email2, ' ', '+'
    expUrl += string(format='(%"user_email=%s&")', user_email2)
    user_affiliation2 = String(Replicate(32B, strlen(user_affiliation)))
    strput, user_affiliation2, user_affiliation
    strreplaceall, user_affiliation2, ' ', '+'
    expUrl += string(format='(%"user_affiliation=%s&")', user_affiliation2)
    if (outputFile ne '') then begin
        basename = file_basename(outputFile)
        version = madgetversion(madurl)
        mad3vers = intarr(3)
        mad3vers[0] = 3
        if (madcompareversions(version, mad3vers) eq -1) then begin
            file_parts = strsplit(basename, '.', /extract)
            extension = file_parts[n_elements(file_parts)-1]
            case extension of
                'hdf5': message, 'Cannot request hdf5 file format for Madrigal2 site.'
                'h5': message, 'Cannot request hdf5 file format for Madrigal2 site.'
                'hdf': message, 'Cannot request hdf5 file format for Madrigal2 site.'
                'nc': message, 'Cannot request netCDF4 file format for Madrigal2 site.'   
            endcase
        endif
        expUrl += string(format='(%"output=%s&")', basename)
        resultFile = outputFile
    endif else begin
        resultFile = 'idl_temp_file.txt'
    endelse
    
    ;make sure resultFile does not exist
    if (file_test(resultFile)) then begin
        file_delete, resultFile
    endif
    

    if (verbose NE 0) then print, 'Calling Madrigal using wget...'
    
    ; try wget
    wgetCmd = 'wget -q --timeout=600 --tries=4 -O ' + resultFile + ' "' + expUrl + '"'
    
    SPAWN, wgetCmd, result, errresult
    errresult = STRJOIN(errresult, /SINGLE)
    if (STRLEN(errresult) GT 4) then begin
	    print, 'Error: ' + errresult + ' Possibly wget not installed on your system - you need to install it first to run maddownloadfile or madglobaldownload'
	    return, -1
    endif

    if (outputFile ne '') then begin
        nlines = FILE_LINES(outputFile)
        if (nlines eq 0) then begin
            print, 'Timeout running wget - file possibly too big - skipping.'
            return, -1
       endif else begin
            return, 1
       endelse
    endif

    nlines = FILE_LINES('idl_temp_file.txt')
    
    if (nlines eq 0) then begin
        print, 'Timeout running wget - file possibly too big - skipping.'
        return, -1
    endif

    sArr = STRARR(nLines)

    OPENR, inunit, 'idl_temp_file.txt', /GET_LUN
    READF, inunit, sArr
    FREE_LUN, inunit
    FILE_DELETE, 'idl_temp_file.txt',  /ALLOW_NONEXISTENT,  /QUIET

    ; create dataArr set to all zeros
    dataArr = fltarr(numParms, nLines-1)
    
    ; this pass fills out that array
    index = long64(0) ; index different from i only i line has unexpected linefeed
    buffer = ''
    for i=long64(0), nlines-1 do begin
        ; check for error
        if (i LT 10) then begin
            if (STRPOS(sArr[i], '****') NE -1) then begin
                FILE_DELETE, 'idl_temp_file.txt',  /ALLOW_NONEXISTENT,  /QUIET
                message, 'Error encounted: ' + sArr[i]
            endif
        endif
        if (nlines GT 1000) then begin
            if (i MOD 1000 EQ 0) then begin
                if (verbose NE 0) then print, 'Line ',i, ' complete out of ', nlines
            endif
        endif
        thisLine = buffer + sArr[i]
        words = strsplit(thisLine, ' ', /EXTRACT)
        if (N_ELEMENTS(words) LT numParms) then begin
            ; debug coded print, 'Error: two few words in line - buffering: ' + thisLine
            buffer = thisLine
            continue
        endif else begin
            buffer = ''
        endelse
        ; loop through each parm
        for j=0, numParms - 1 do begin
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
	    ;;MOD by Ashton Reimer on August 3, 2011
	    ;;Needed so that index of dataArr does not get larger than what dataArr has been defined on line 137
	    if (index eq nlines-2) then begin
		    break
	    endif
	    ;;End of MOD

        index += 1
    endfor

    if (verbose NE 0) then print, 'madprint complete'

    RETURN, dataArr

END
