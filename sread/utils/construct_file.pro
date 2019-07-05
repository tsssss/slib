;+
; Construct file names with patterns, and often time information.
; The return value is a list of dictionaries, whose keys are:
;   file. A string for the local full file name;
;
; This is a relative isolated module, which can be used to construct an
; array of files for downloading, deleting, reading, writing, etc.
;
; local_paths=. An array of patterns for the local paths.
; time_independent. A boolean. Set it to indicate there is no time format code in the patterns.
; file_times=. An array of UT sec. Set to get fine control on replacing the time format code.
; time_info=. A double or [2]. Set to replace the time format code in the patterns.
; cadence=. A string or time in sec. Set the cadence of the files. Default value is 'day'.
; remote_base_pattern=. A string for the pattern for the URL.
; remote_paths=. An array of patterns for the remote paths.
;-
function construct_file, pattern, errmsg=errmsg, $
    file_times=file_times, time=time, cadence=cadence, version=version, _extra=extra

    errmsg = ''
    retval = ''
    
    if n_elements(pattern) eq 0 then return, retval
    if n_elements(cadence) eq 0 then cadence = 'day'
    if n_elements(file_times) eq 0 then begin
        if n_elements(time) eq 0 then file_times = break_down_times(time, cadence)
    endif
    if n_elements(version) eq 0 then version = '.*'
    
    type = strlowcase(typename(pattern))
    if type eq 'dictionary' or type eq 'hash' then begin
        foreach key, pattern.keys() do begin
            pattern[key] = construct_file(pattern[key], $
                errmsg=errmsg, file_times=file_times, version=version, _extra=extra)
        endforeach
        return, pattern
    endif else if type eq 'list' then begin
        foreach key, pattern, ii do pattern[ii] = construct_file(key, $
            errmsg=errmsg, file_times=file_times, version=version, _extra=extra)
    endif else if type ne 'string' then return, retval


;---Construct files from patterns (and file_times)
    files = pattern
    if n_elements(file_times) ne 0 then $
        files = apply_time_to_pattern(files, file_times)
    files = apply_version_to_pattern(files, version)

    return, files

end