;+
; Type: procedure.
; Purpose: Prepare filename and time range.
; Parameters:
;   fn, in/out, string/strarr[n], req. File names.
;   tr, in/out, dblarr[2]/dblarr[n,2], req. Time range in ut.
; Keywords:
;   pattern, in, string, opt. File pattern.
;   source, in, string, opt. File source.
; Notes: The module treats the data as a whole, so only contains one time range.
;   Possible inputs can be: (1) File names only: test existence of the file
;   names, find the time range; (2) File pattern and time range: use the time
;   range to convert file pattern into file names, then same as (1); (3) File
;   source and time range: use a dictionary to look up the file pattern
;   corresponding to the given file source, then same as (2); (4) Time range
;   only: use the default file source, then same as (3). In any cases, time
;   range can be replaced by time, the given time is used to find file name.
;       If file name is given, all pattern information including file pattern
;   and source are skipped, time range is determined by file if it is missing.
;   If file name is missing, then must provide time information including time
;   or time range. Pattern information can be auto-determined to some extend,
;   and can be manually set when necessary. 
; Dependence: none.
; History:
;   2014-02-03, Sheng Tian, create.
;-

pro srprep, fn, tr, vars, $
    pattern = ptn, source = src

    if keyword_set(src) then srfindsource, src, ptn, vars
