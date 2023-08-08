;+
; NAME: 
;    madglobaldownload, madurl, outputDir, user_fullname, user_email, user_affiliation, startDate, endDate, 
;                          inst, kindats, format, expName,  fileDesc
;
; PURPOSE
;     madglobaldownload is a procedure to search through the entire Madrigal database
;     for appropriate data files to download to outputDir
;
; INPUTS: 
;
;        madurl - url to homepage of site to be searched (Example: 
;              'http://www.haystack.mit.edu/madrigal/'
;
;        outputDir - the local directory to store the downloaded files in. Must exist.
;                 (Example: '/tmp/isprint.txt')
;
;        user_fullname - the full user name (Example: 'Bill Rideout')
;
;        user email -  Example: 'brideout@haystack.mit.edu'
;
;        user_affiliation - Example: 'MIT'
;
;        startDate - a time in IDL Julian Date format at which to begin the search
;
;        endDate - a time in IDL Julian Date format at which to end the search
;
;        inst - instrument code (integer).  See 
;            http://cedar.openmadrigal.org/instMetadata/
;            for this list. Examples: 30 for Millstone
;            Hill Incoherent Scatter Radar, 80 for Sondrestrom Incoherent 
;            Scatter Radar
;
;    Optional inputs
;
;        kindats - is an optional array of kindat (kinds of data) codes to accept.
;           The default is a null pointer, which will accept all kindats.
;
;        format - ascii or hdf5 or netCDF4.  Default is ascii. netCDF4 only works with Madrigal 3 or greater
;  
;        expName - a case insensitive string as used by strmatch that matches the experiment
;           name.  Default is zero-length string, which matches all experiment names. 
;           For example, *ipy* matches any name containing ipy, IPY, etc.
;
;        fileDesc - a case insensitive string as used by strmatch that matches the file description.
;           Default is zero-length string, which matches all file descriptions.
;
; OUTPUT: Nothing.
;
;    Affects: Writes downloaded files to outputDir
;    
;
; EXAMPLE: 
;   madglobaldownload, 'http://www.haystack.mit.edu/madrigal/',  $
;                         '/tmp/downloads', $
;                         'Bill Rideout',  'brideout@haystack.mit.edu', 'MIT', $
;                         julday(1,19,1998,0,0,0),  julday(1,21,1998,23,59,59), 30, $
;                         3410, 'hdf5'
;
;  $Id: madglobaldownload.pro 6852 2019-06-17 15:12:19Z brideout $
;
pro madglobaldownload, madurl, outputDir, user_fullname, user_email, user_affiliation, startDate, endDate, $
                           inst, kindats, format, expName,  fileDesc
                           
    ; determine if any default parameters need to be set
    if (n_params() lt 8) then begin
        message, 'Too few parameters specified - see usage in madglobaldownload.pro'
    endif
    
    if (n_params() lt 9) then begin
        kindats = ptr_new()
    endif
    
    if (n_params() lt 10) then begin
        format = 'ascii'
    endif
    
    if (n_params() lt 11) then begin
        expName = ''
    endif
    
    if (n_params() lt 12) then begin
        fileDesc = ''
    endif
    
    if ((format NE 'ascii') AND (format NE 'hdf5') AND (format NE 'netCDF4')) then begin
      message, 'format must be ascii or hdf5 or netCDF4'
    endif
    
    ; convert time arguments
    startYear = 0
    startMonth = 0
    startDay = 0
    startHour = 0
    startMin = 0
    startSec = 0
    endYear = 0
    endMonth = 0
    endDay = 0
    endHour = 0
    endMin = 0
    endSec = 0
    
    CALDAT, startDate, startMonth, startDay, startYear, startHour , startMin, startSec
    CALDAT, endDate, endMonth, endDay, endYear, endHour , endMin, endSec

    
    ; get an array of experiments that match the input arguments
    expArr = madgetexperiments(madurl, inst, startYear, startMonth, startDay, startHour , startMin, startSec, $
                                                          endYear, endMonth, endDay, endHour , endMin, endSec, 1)
                                                          
    ; print error message if no experiments found
    resultSize = size(expArr)
    if (resultSize[0] eq 0) then begin
        close, 10
        message, 'No experiments found that matched the input arguments'
    endif
    
    for i=0, n_elements(expArr)-1 do begin
        
        ; apply experiment name filter, if needed
        if (strlen(expName) gt 0) then begin
            if (strmatch(expArr[i].name, expName, /FOLD_CASE) eq 0) then continue
        endif
        
        ; for each experiment, find all default files
        fileArr = madgetexperimentfiles(madUrl, long64(expArr[i].strid))
        
        ; check for empty result
        resultSize = size(fileArr)
        if (resultSize[0] eq 0) then continue
        
        ; loop through each default file
        for j=0, n_elements(fileArr)-1 do begin
        
            ; ignore non-default files
            if (fileArr[j].category ne 1) then continue
            
            ; apply kindat filter, if needed
            resultSize = size(kindats)
            if (resultSize[1] ne 10) then begin
                found = 0 ; loop state variable
                for k=0, n_elements(kindats)-1 do begin
                    if (fileArr[j].kindat eq kindats[k]) then found = 1
                endfor
                if (found eq 0) then continue ; skip this default file
            endif
            
            ; apply fileDesc filter, if needed
            if (strlen(fileDesc) gt 0) then begin
                if (strmatch(fileArr[j].status, fileDesc, /FOLD_CASE) eq 0) then continue ; skip this default file
            endif
            
            print , 'Downloading file ', fileArr[j].name

            if (format EQ 'ascii') then begin
                newBasename = FILE_BASENAME(fileArr[j].name) + '.txt'
            endif else begin
                newBasename = FILE_BASENAME(fileArr[j].name) + '.hdf5'
            endelse
            
            ; run maddownloadfile
            maddownloadfile, madurl, fileArr[j].name, outputDir + '/' + newBasename, user_fullname, user_email, user_affiliation, format
            
        endfor ; end loop through files
        
        ;wait, 2.0
        
    endfor ; end loop through experiments
                                                          
    print, 'madglobaldownload complete'
                           
end
