;+
; NAME: 
;    madsimpleprint(madurl, fullFilename, user_fullname, user_email, user_affiliation)
;
; PURPOSE: 
;    madSimplePrint prints the data in the given file is a simple ascii format.
;
;        madSimplePrint prints only the parameters in the file, without filters or derived
;        parameters.  To choose which parameters to print, to print derived parameters, or
;        to filter the data, use isprint instead.
;
; INPUTS: 
;      madurl - scalar string giving a fully qualified url to the Madrigal site
;      fullFilename - full path to experiment file as returned by madGetExperimentFiles.
;      user_fullname - full name of user making request
;      user_email - email address of user making request
;      user_affiliation - affiliation of user making request
;
; OUTPUT: a structure with following fields:
;     1. parameters - an array of strings giving the mnemonics of the parameters.  Equal to the number of columns in data
;     2. data - a two dimensional array of double.  Number of columns = number of parameters above.  Number of rows
;         is the number of measurments.  Note that Madrigal often contains a number a measurments at the same time
;         (such as when a radar makes different range measurements at the same time), so two or more rows may have the same time.
; EXAMPLE: 
;     result = madSimplePrint('http://millstonehill.haystack.mit.edu', '/opt/madrigal/blah/mlh980120g.001', $
;                                              'Bill Rideout', 'brideout@haystack.mit.edu', 'MIT')
;
; $Id: madsimpleprint.pro 6810 2019-03-28 19:01:24Z brideout $
;
FUNCTION madSimplePrint, madurl,  fullFilename, user_fullname, user_email, user_affiliation

    ; determine if needed parameters set
    if (n_params() lt 5) then begin
      message, 'Too few parameters specified - see usage in madsimpleprint.pro'
    endif

    ; the first step is to call madGetExperimentFileParameters to find out what parameters to request
    parms = madGetExperimentFileParameters(madurl, fullFilename)
    parmStr = ''
    for i=0, n_elements(parms)-1 do begin
        if (parms[i].isMeasured eq 0) then continue ; skip derived parameters
        if (parms[i].isAddIncrement eq 1) then continue ; skip additional increment
        if (strlen(parmStr) eq 0) then begin
            parmStr = parmStr + parms[i].mnemonic
        endif else begin
            parmStr = parmStr + ',' + parms[i].mnemonic
        endelse
    endfor
    
    ; now call madprint without filters
    simpleData = madprint(madurl,  fullFilename, parmStr, '', user_fullname, user_email, user_affiliation)
    
    ; create structure to return
    parmArray = strsplit(parmStr, ',', /EXTRACT, /PRESERVE_NULL)
    result = {parameters:parmArray, data:simpleData}
    
    return, result
END
