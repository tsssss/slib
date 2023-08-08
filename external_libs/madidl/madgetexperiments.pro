;+
; NAME: 
;    madgetexperiments(madurl, instcode, startyear, startmonth, startday, starthour, startmin, startsec,
;                                      endyear, endmonth, endday, endhour, endmin, endsec, local)
;
; PURPOSE: 
;    Get information on experiments for a given instrument and date range
;
; INPUTS: 
;      madurl - scalar string giving a fully qualified url to the Madrigal site
;      instcode = int or array of ints representing instrument code(s). Special value of 0 selects all instruments.
;      startyear, startmonth, startday, starthour, startmin, startsec - 6 ints representing start time
;      endyear, endmonth, endday, endhour, endmin, endsec - 6 ints representing end time
;      local - 0 if all sites desired, 1 (default) if only local experiments desired
;
; OUTPUT: an array of structures representing experiments between the dates with the following fields:
;	1. strid (string) Example: "10000111".  Uniquely identifies experiment. Can be converted to a long long.
;         Not stored as a long long because that just doesn't seem to work, so user needs to convert.
;   2. url (string) Example: 'http://www.haystack.mit.edu/cgi-bin/madtoc/1997/mlh/03dec97'
;         Deprecated - use realUrl field instead (described below)
;   3. name (string) Example: 'Wide Latitude Substorm Study'
;   4. siteid (int) Example: 1
;   5. sitename (string) Example: 'Millstone Hill Observatory'
;   6. instcode (int) Code of instrument. Example: 30
;   7. instname (string) Instrument name. Example: 'Millstone Hill Incoherent Scatter Radar'
;   8. startyear, startmonth, startday, starthour, startmin, startsec - 6 ints representing start time of experiments
;   9. endyear, endmonth, endday, endhour, endmin, endsec - 6 ints representing end time of experiments
;   10. isLocal - 1 if a local experiment, 0 if not
;   11. madrigalUrl - url of Madrigal site.  Used if not a local experiment.
;   12. pi - name of experiment PI
;   13. piemail - email of experiment PI
;   14. realUrl - real url to experiment web page
;   If no experiements found, returns a Null Pointer (IDL does not allow empty arrays)
;
;    Note that if the returned experiment is not local, the experiment id will be -1.  This means that you
;    will need to rerun madgetexperiments with the url of the 
;    non-local experiment (experiment.madrigalUrl).
;    This is because 
;    while Madrigal sites share metadata about experiments, the real experiment ids are only
;    known by the individual Madrigal sites.  See example_madidl.pro for an example of this
;           for an example of this.
; EXAMPLE: 
;     result = madGetExperiments('http://millstonehill.haystack.mit.edu', 30, 1998,1,1,0,0,0, 1998,1,31,23,59,59,1)
;
; $Id: madgetexperiments.pro 6810 2019-03-28 19:01:24Z brideout $
;
FUNCTION madGetExperiments, madurl,  instcode, startyear, startmonth, startday, starthour, startmin, startsec, $
                                      endyear, endmonth, endday, endhour, endmin, endsec, local

    scriptName = 'getExperimentsService.py'
    
    ; determine if needed parameters set
    if (n_params() lt 14) then begin
      message, 'Too few parameters specified - see usage in madgetexperiments.pro'
    endif
    
    if (n_params() lt 15) then begin
        local = 1
    endif
    
    ; get cgiUrl
    cgiUrl = madgetcgiurl(madurl)
    
    ; the first thing we need to do is read siteTab.txt to get remote Madrigal urls
    siteUrl = cgiUrl + 'getMetadata?fileType=5'
    
    ; try wget
    wgetCmd = 'wget -q -O idl_temp_file.txt "' + siteUrl + '"'
    spawn, wgetCmd, listing, EXIT_STATUS=error
    
    ; see if wget worked
    error = STRCOMPRESS(error, /REMOVE_ALL)
    if (error NE 0) then begin
        message, 'got error <' + error + '> - perhaps you need to install wget?'
    endif

    nlines = FILE_LINES('idl_temp_file.txt')
    
    if nlines eq 0 then begin
        return, ptr_new()
    endif

    lines = STRARR(nLines)

    OPENR, inunit, 'idl_temp_file.txt', /GET_LUN
    READF, inunit, lines
    FREE_LUN, inunit
    FILE_DELETE, 'idl_temp_file.txt',  /ALLOW_NONEXISTENT,  /QUIET

    ; this first pass through the data is simply to get a count
    totalLines = 0
    for i=0, N_ELEMENTS(lines)-1 do begin
        words = strsplit(lines[i], ',', /EXTRACT, /PRESERVE_NULL)
        if (N_ELEMENTS(words) LT 4) then continue
        totalLines += 1
    endfor
    
    ; create default siteArr
    siteDefault = {id:0, madrigalUrl:""} 
    siteArr = REPLICATE(siteDefault, totalLines) 
    
    ; this pass fills out that array
    index = 0
    for i=0, N_ELEMENTS(lines)-1 do begin
        words = strsplit(lines[i], ',', /EXTRACT, /PRESERVE_NULL)
        if (N_ELEMENTS(words) LT 4) then continue
        siteArr[index].id = long(words[0])
        url = string(format='(%"http://%s/%s")', words[2], words[3])
        siteArr[index].madrigalUrl = url
        index += 1
    endfor
    
    
    ; now call the main method to get experiments
    expUrl = cgiUrl + scriptName + '?'
    
    ; find out if instcode is an int or an array
    result = size(instcode)
    if (result[0] eq 0) then begin
        expUrl += string(format='(%"code=%i&")', instcode)
    endif else begin
        for i=0, n_elements(instcode)-1 do begin
            expUrl += string(format='(%"code=%i&")', instcode[i])
        endfor
    endelse
    
    ; append times
    expUrl += string(format='(%"startyear=%i&")', startyear)
    expUrl += string(format='(%"startmonth=%i&")', startmonth)
    expUrl += string(format='(%"startday=%i&")', startday)
    expUrl += string(format='(%"starthour=%i&")', starthour)
    expUrl += string(format='(%"startmin=%i&")', startmin)
    expUrl += string(format='(%"startsec=%i&")', startsec)
    expUrl += string(format='(%"endyear=%i&")', endyear)
    expUrl += string(format='(%"endmonth=%i&")', endmonth)
    expUrl += string(format='(%"endday=%i&")', endday)
    expUrl += string(format='(%"endhour=%i&")', endhour)
    expUrl += string(format='(%"endmin=%i&")', endmin)
    expUrl += string(format='(%"endsec=%i&")', endsec)
    
    expUrl += string(format='(%"local=%i")', local)


    ; try wget
    wgetCmd = 'wget -q -O idl_temp_file.txt "' + expUrl + '"'
    spawn, wgetCmd, listing, EXIT_STATUS=error
    
    ; see if wget worked
    error = STRCOMPRESS(error, /REMOVE_ALL)
    if (error NE 0) then begin
        message, 'got error <' + error + '> - perhaps you need to install wget?'
    endif

    nlines = FILE_LINES('idl_temp_file.txt')
    if nlines eq 0 then begin
        return, ptr_new()
    endif

    lines = STRARR(nLines)

    OPENR, inunit, 'idl_temp_file.txt', /GET_LUN
    READF, inunit, lines
    FREE_LUN, inunit
    FILE_DELETE, 'idl_temp_file.txt',  /ALLOW_NONEXISTENT,  /QUIET
    
    ; this first pass through the data is simply to get a count
    totalLines = 0
    for i=0, N_ELEMENTS(lines)-1 do begin
        words = strsplit(lines[i], ',', /EXTRACT, /PRESERVE_NULL)
        if (N_ELEMENTS(words) LT 20) then continue
        totalLines += 1
    endfor
    
    if (totalLines eq 0) then begin
        return, ptr_new()
    endif
    
    ; create default expArr
    expDefault = {experiment, strid:"missing", url:"", name:"", siteid:0L, sitename:"", instcode:0L,instname:"",  $
         startyear:0,startmonth:0,startday:0,starthour:0,startmin:0,startsec:0,  $
         endyear:0,endmonth:0,endday:0,endhour:0,endmin:0,endsec:0,isLocal:0,madrigalUrl:"", $
         pi:"unknown", piemail:"unknown", realUrl:""} 
    expArr = REPLICATE({experiment}, totalLines) 
    
    ; this pass fills out that array
    index = 0
    for i=0, N_ELEMENTS(lines)-1 do begin
        words = strsplit(lines[i], ',', /EXTRACT, /PRESERVE_NULL)
        if (N_ELEMENTS(words) LT 20) then continue
        expArr[index].strid = words[0]
        expArr[index].url = words[1]
        expArr[index].name = words[2]
        expArr[index].siteid = long(words[3])
        expArr[index].sitename = words[4]
        expArr[index].instcode = long(words[5])
        expArr[index].instname = words[6]
        expArr[index].startyear = uint(words[7])
        expArr[index].startmonth = uint(words[8])
        expArr[index].startday = uint(words[9])
        expArr[index].starthour = uint(words[10])
        expArr[index].startmin = uint(words[11])
        expArr[index].startsec = uint(words[12])
        expArr[index].endyear = uint(words[13])
        expArr[index].endmonth = uint(words[14])
        expArr[index].endday = uint(words[15])
        expArr[index].endhour = uint(words[16])
        expArr[index].endmin = uint(words[17])
        expArr[index].endsec = uint(words[18])
        expArr[index].isLocal = uint(words[19])
        if (expArr[index].isLocal eq 0) then begin
            expArr[index].strid = '-1'
        endif
        for j=0, n_elements(siteArr)-1 do begin
            if (siteArr[j].id eq expArr[index].siteid) then begin
                expArr[index].madrigalUrl = siteArr[j].madrigalUrl
                break
            endif
        endfor
        if (N_ELEMENTS(words) GT 21) then begin
            expArr[index].pi = words[20]
            expArr[index].piemail = words[21]
        endif else begin
            expArr[index].pi = "unknown"
            expArr[index].piemail = "unknown"
        endelse

        ; create realUrl
        realUrl = expArr[index].url
        strreplaceall, realUrl, '/madtoc/', '/madExperiment.cgi?exp='
        realUrl = realUrl + '&displayLevel=0&expTitle='
        title = expArr[index].name
        strreplaceall, title, ' ', '+'
        expArr[index].realUrl = realUrl + title
        
        ; now already sorted
        
        
        index += 1
    endfor
    
    
	RETURN, expArr
END
