;+
; Look up the local index file for each file.
;
; file. A string for full file name.
; index_file. A string of the base name of the index file.
; lines=. The actual lines of the index_file.
;
; The index_file and basenames are assumed to be in the same folder.
;=
function lookup_index_per_file, file, index_file, silent=silent, lines=lines

    retval = !null
    if n_elements(file) eq 0 then return, retval

    if n_elements(lines) eq 0 then begin
        if n_elements(index_file) ne 1 then return, retval
        if file_test(index_file) eq 0 then return, retval
        lines = read_all_lines(index_file[0])
    endif
    if n_elements(lines) eq 1 and lines[0] eq '' then return, retval

    base_name = fgetbase(file)
    the_files = stregex(lines, base_name, extract=1, fold_case=1)
    index = where(the_files ne '', nfile)
    if nfile eq 0 then return, retval
    base_names = the_files[index]
    file_path = fgetpath(file)
    ofiles = strarr(nfile)
    for ii=0,nfile-1 do begin
        ofiles[ii] = join_path([file_path,base_names[ii]])
    endfor
    return, ofiles

end
