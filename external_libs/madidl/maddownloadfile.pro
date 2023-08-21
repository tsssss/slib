;+
; NAME: 
;    maddownloadfile, madurl, fullFilename, outputFile, user_fullname, user_email, user_affiliation, format
;
; PURPOSE: 
;    downloads a Madrigal file in ascii, Hdf5, or netCDF4 format to local computer
;
; INPUTS: 
;      madurl - scalar string giving a fully qualified url to the Madrigal site
;      fullFilename - full path to experiment file as returned by madGetExperimentFiles.
;      outputFile - path to save file locally
;      user_fullname - full name of user making request
;      user_email - email address of user making request
;      user_affiliation - affiliation of user making request
;      format - 'ascii'or 'hdf5' or 'netCDF4'. Default is ascii. netCDF4 requires Madrigal3
;
; EXAMPLE: 
;     maddownloadfile, 'http://millstonehill.haystack.mit.edu', '/opt/madrigal/experiments/1998/mlh/20jan98/mlh980120g.002', '/tmp/junk.hdf5', &
;                                   'Bill Rideout', 'brideout@haystack.mit.edu', 'MIT', 'hdf5'
;
; $Id: maddownloadfile.pro 6974 2019-07-29 19:55:06Z brideout $
;
PRO maddownloadfile, madurl,  fullFilename, outputFile, user_fullname, user_email, user_affiliation, format

    on_error, 2
    
    ; determine if needed parameters set
    if (n_params() lt 6) then begin
      message, 'Too few parameters specified - see usage in maddownloadfile.pro'
    endif
    
    if (n_params() lt 7) then begin
        format = 'ascii'
    endif
    
    if ((format NE 'ascii') AND (format NE 'hdf5') AND (format NE 'netCDF4')) then begin
      message, 'format must be ascii or hdf5 or netCDF4'
    endif
    
    if (format EQ 'netCDF4') then begin
        version = madgetversion(madurl)
        mad3vers = intarr(3)
        mad3vers[0] = 3
        if (~madcompareversions(version, mad3vers)) then begin
            print, version
            print, mad3vers
            message, 'netCDF4 format can only be requested from Madrigal 3.0 or higher sites'
        endif
    endif 
	
    if (format EQ 'ascii') then begin
        fileType = -1
    endif
    if (format EQ 'hdf5') then begin
        fileType = -2
    endif
    if (format EQ 'netCDF4') then begin
        fileType = -3
    endif
	
    cgiUrl = madgetcgiurl(madurl)
    ; build command
    cmd = string(format='(%"wget -q --timeout=600 --tries=4 -O %s ")', outputFile)
    scriptName = 'getMadfile.cgi'
    expUrl = '"' + cgiUrl + scriptName + '?'
    expUrl += string(format='(%"fileName=%s&")', fullFilename)
    expUrl += string(format='(%"fileType=%i&")', fileType)
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
    cmd += expUrl
    cmd += '"'

    ; run command
    SPAWN, cmd, result, errresult
    errresult = STRJOIN(errresult, /SINGLE)
    if (STRLEN(errresult) GT 4) then begin
        print, 'Error: ' + errresult + ' Possibly wget not installed on your system - you need to install it first to run maddownloadfile or madglobaldownload'
        return
    endif
    
    ; if ascii, see if it needs to be uncompressed
    if (format EQ 'ascii') then begin
      ; verify gunzip exists
      cmd = 'gunzip -h'
      SPAWN, cmd, result, errresult, EXIT_STATUS=status
      if (status NE 0) then begin
        print, 'Error - gunzip not installed - required: ' + errresult
        return
      endif
      ; cp file to have gzip extension
      cmd = string(format='(%"cp %s %s.gz")', outputFile, outputFile)
      SPAWN, cmd, result, errresult, EXIT_STATUS=status
      if (status NE 0) then begin
        print, 'Error: ' + errresult 
        return
      endif
      cmd = string(format='(%"gunzip -f %s.gz")', outputFile)
      SPAWN, cmd, result, errresult, EXIT_STATUS=status
      if (status NE 0) then begin
        ; may not have been gzip format
        cmd = string(format='(%"mv %s.gz %s")', outputFile, outputFile)
        SPAWN, cmd, result, errresult
      endif
      
    endif
	
END
