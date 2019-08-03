;+
; Look up the local index file for each basename. Find the one of highest order.
;
; basenames. A string or an array of N base names.
; local_paths. A string or an array of N local full paths.
; index_file. A string of the base name of the index file.
;
; The index_file and basenames are assumed to be in the same folder.
;=
function lookup_index_file, files, index_file, silent=silent

    retval = ''
    nfile = n_elements(files)
    if nfile eq 0 then return, retval

    ofiles = files
    if n_elements(index_file) ne 1 then return, ''
    if file_test(index_file) eq 0 then return, ''
    lines = read_all_lines(index_file[0])
    if n_elements(lines) eq 1 and lines[0] eq '' then return, ''

    foreach file, files, ii do begin
        if file_test(file) eq 1 then continue
        base_name = fgetbase(file)
        the_files = stregex(lines, base_name, /extract, /fold_case)
        index = where(the_files ne '', count)
        if count eq 0 then begin
            ofiles[ii] = ''
            if ~keyword_set(silent) then message, 'No file is found for given pattern: '+base_name+' ...', /continue
            continue
        endif
        the_files = the_files[index]
        base_name = (count eq 1)? the_files[0]: (the_files[sort(the_files)])[-1]
        ofiles[ii] = join_path([fgetpath(file),base_name])
    endforeach

    return, ofiles

end
