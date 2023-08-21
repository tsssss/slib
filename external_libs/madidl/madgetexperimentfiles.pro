;+
; NAME: 
;    madgetexperimentfiles(madurl, expid, getnondefault)
;
; PURPOSE: 
;    returns a list of all  Madrigal Experiment Files for a given experiment id
;
; INPUTS: 
;      madurl - scalar string giving a fully qualified url to the Madrigal site
;      expid - experiment id as returned by madgetexperiments
;      getnondefault - an optional argument.  If 1, get all files, including non-default.  If 0 (the default)
;             get only default files. In general, non-default files should be used with caution, and most users
;             should set this argument to 0.
;
; OUTPUT: an array of structures representing experiment files for that experiment with the following fields:
;     1. name (string) Example '/opt/madrigal/blah/mlh980120g.001'
;     2. kindat (int) Kindat code.  Example: 3001
;     3. kindatdesc (string) Kindat description: Example 'Basic Derived Parameters'
;     4. category (int) (1=default, 2=variant, 3=history, 4=real-time)
;     5. status (string)('preliminary', 'final', or any other description)
;     6. permission (int)  0 for public, 1 for private
;     7. expId - experiment id (int) of the experiment this MadrigalExperimentFile belongs in
;     8. doi - Citable URL of file
;   If no experiement files found, returns a Null Pointer (IDL does not allow empty arrays)
; EXAMPLE: 
;     result = madGetExperimentFiles('http://millstonehill.haystack.mit.edu', 300041, 0)
;
; $Id: madgetexperimentfiles.pro 6810 2019-03-28 19:01:24Z brideout $
;
FUNCTION madGetExperimentFiles, madurl,  expId, getNonDefault

    on_error, 2
    
    ; convert expId to number if needed
    expId = long64(expId)

    scriptName = 'getExperimentFilesService.py'
    
    ; determine if needed parameters set
    if (n_params() lt 2) then begin
      message, 'Too few parameters specified - see usage in madgetexperimentfiles.pro'
    endif

    ; determine if non local exp id used
    if (expId eq -1) then begin
      message, 'Illegal exp id.  Probably caused by using a non-local experiment.  For non-local experiment, you need to call madgetexperiments a second time with the right url. See example_madidl.pro for an example call.'
    endif
    
    if (n_params() lt 3) then begin
        getNonDefault = 0
    endif
    
    ; get cgiUrl
    cgiUrl = madgetcgiurl(madurl)
    
    
    ; now call the main method to get experiment files
    expUrl = cgiUrl + scriptName + '?'
    expUrl += string(format='(%"id=%i")', expId)
    
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
        if (N_ELEMENTS(words) LT 6) then continue
        if (getNonDefault eq 0) then begin
            if (uint(words[3]) ne 1) then continue ; skip non-default file
        endif
        totalLines += 1
    endfor
    
    if (totalLines eq 0) then begin
        return, ptr_new()
    endif
    
    ; create default expFileArr
    expFileDefault = {name:"", kindat:0L, kindatdesc:"", category:0, status:"", permission:0,expid:0L,doi:""} 
    expFileArr = REPLICATE(expFileDefault, totalLines) 
    
    ; this pass fills out that array
    index = 0
    for i=0, N_ELEMENTS(lines)-1 do begin
        words = strsplit(lines[i], ',', /EXTRACT, /PRESERVE_NULL)
        if (N_ELEMENTS(words) LT 6) then continue
        if (getNonDefault eq 0) then begin
            if (uint(words[3]) ne 1) then continue ; skip non-default file
        endif
        expFileArr[index].name = words[0]
        expFileArr[index].kindat = long(words[1])
        expFileArr[index].kindatdesc = words[2]
        expFileArr[index].category = uint(words[3])
        expFileArr[index].status = words[4]
        expFileArr[index].permission = uint(words[5])
        expFileArr[index].expid = long(expid)
        if (N_ELEMENTS(words) GT 6) then begin
            expFileArr[index].doi = words[6]
        endif

        index += 1
    endfor
    
	RETURN, expFileArr
END
