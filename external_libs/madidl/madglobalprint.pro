;+
; NAME: 
;    madglobalprint, madurl, parms, output, user_fullname, user_email, user_affiliation, startDate, endDate, 
;                          inst, filters, kindats, expName,  fileDesc, format
;
; PURPOSE
;     madglobalprint is a procedure to search through the entire Madrigal database
;     for appropriate data to print in ascii to a file or to files in a directory in Hdf5 or netCDF4
;
; INPUTS: 
;
;        madurl - url to homepage of site to be searched (Example: 
;              'http://www.haystack.mit.edu/madrigal/'
;
;        parms - a comma delimited string listing the desired Madrigal 
;            parameters in mnemonic form.  
;            (Example: 'year,month,day,hour,min,sec,gdalt,dte,te').  
;            Ascii space-separated data will be returned in the same  
;            order as given in this string. See 
;            http://cedar.openmadrigal.org/parameterMetadata/
;            for all possible parameters.
;
;        output - the local file or directory name to store the resulting data.
;                 (Example: '/tmp/isprint.txt' or '/tmp') If a directory, a format
;                 may be specified, with ascii the default.
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
;        filters - is the optional filters requested in exactly the form given in isprint
;         command line (example = 'filter=gdalt,,500 filter=ti,500,1000')
;         See:  Documentation->Administrator's Guide->Using isprint for file quick looks for details
;
;        kindats - is an optional array of kindat (kinds of data) codes to accept.
;           The default is a null pointer, which will accept all kindats.
;  
;        expName - a case insensitive string as used by strmatch that matches the experiment
;           name.  Default is zero-length string, which matches all experiment names.
;           For example, *ipy* matches any name containing ipy, IPY, etc.
;
;        fileDesc - a case insensitive string as used by strmatch that matches the file description.
;           Default is zero-length string, which matches all file descriptions.
;
;        format - 'ascii', 'hdf5', or 'netCDF4'.  The default is ascii
;
; OUTPUT: Nothing.
;
;    Affects: Writes results to output file or directory
;    
;
; EXAMPLE: 
;   madglobalprint, 'http://www.haystack.mit.edu/madrigal/',  $
;                         'year,month,day,hour,min,sec,gdalt,dte,te', $
;                         '/tmp/isprint.txt', $
;                         'Bill Rideout',  'brideout@haystack.mit.edu', 'MIT', $
;                         julday(1,19,1998,0,0,0),  julday(1,21,1998,23,59,59), 30
;
;  $Id: madglobalprint.pro 6810 2019-03-28 19:01:24Z brideout $
;
pro madglobalprint, madurl, parms, output, user_fullname, user_email, user_affiliation, startDate, endDate, $
                           inst, filters, kindats, expName,  fileDesc, format
                           
    ; determine if any default parameters need to be set
    if (n_params() lt 9) then begin
        message, 'Too few parameters specified - see usage in madglobalprint.pro'
    endif
    
    if (n_params() lt 10) then begin
        filters = ''
    endif
    
    if (n_params() lt 11) then begin
        kindats = ptr_new()
    endif
    
    if (n_params() lt 12) then begin
        expName = ''
    endif
    
    if (n_params() lt 13) then begin
        fileDesc = ''
    endif

    if (n_params() lt 14) then begin
        format = 'ascii'
    endif
    
    ; get numParms
    parmList = strsplit(parms, ',', /EXTRACT, /PRESERVE_NULL)
    numParms = n_elements(parmList)
    if (strlen(parmList[0]) eq 0) then begin
         message, 'At least one parameter must be specified'
    endif
    
    ; build a format string
    formatStr = '(%"%f '
    for i=1, numParms-1 do begin
        formatStr = formatStr + '%f '
    endfor
    formatStr = formatStr + '")'


    if (file_test(output, /DIRECTORY)) then begin
        isDir = 1
    endif else begin
        isDir = 0
        ; open output file
        openw, 10, output
        printf, 10, parms
    endelse
    
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
    
    ; handle the case when experiments extend outside time range
    timeFiltStr1 = string(format='(%" date1=%02i/%02i/%04i time1=%02i:%02i:%02i ")', $
                            startMonth, startDay, startYear, startHour , startMin, startSec)
    timeFiltStr2 = string(format='(%"date2=%02i/%02i/%04i time2=%02i:%02i:%02i ")', $
                            endMonth, endDay, endYear, endHour , endMin, endSec)
    filters = filters + timeFiltStr1 + timeFiltStr2
    
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
            
            print , 'Working on file ', fileArr[j].name
            
            ; run madprint
            if (isDir eq 1) then begin
                case format of
                    'ascii': outputFile = output + '/' + file_basename(fileArr[j].name) + '.txt'
                    'netCDF4': outputFile = output + '/' + file_basename(fileArr[j].name) + '.nc'
                    'hdf5': outputFile = output + '/' + file_basename(fileArr[j].name)
                endcase
                data = madprint(madurl, fileArr[j].name, parms, filters, user_fullname, user_email, user_affiliation, 1, 1, outputFile)
                if (data eq -1) then print, 'error in file ' + fileArr[j].name + ', skipping'
                continue
            endif
            data = madprint(madurl, fileArr[j].name, parms, filters, user_fullname, user_email, user_affiliation, 1)
            dataSize = size(data)
            if (dataSize[0] eq 1) then continue ; no data found in that file
         
            ; loop through each data row
            result = size(data)
            for k=0L, result[2]-1 do begin
                printf, 10, FORMAT=formatStr,  data[*,k]
            endfor
            
        endfor ; end loop through files
        
    endfor ; end loop through experiments
                                                          
   
    ; close output file
    close, 10
    
    print, 'madglobalprint complete'
                           
end
