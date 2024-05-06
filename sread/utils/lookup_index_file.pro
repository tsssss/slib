;+
; Look up the local index file for each basename. Find the one of highest order.
;
; basenames. A string or an array of N base names.
; local_paths. A string or an array of N local full paths.
; index_file. A string of the base name of the index file.
; get_all_match=. Set to return all filenames that match the pattern.
; 
;
; The index_file and basenames are assumed to be in the same folder.
;-
function lookup_index_file, files, index_file, silent=silent, lines=lines, get_all_match=get_all_match

    retval = ''
    nfile = n_elements(files)
    if nfile eq 0 then return, retval
    

    ofiles = list(files, extract=1)
    if n_elements(lines) eq 0 then begin
        if n_elements(index_file) ne 1 then return, ''
        if file_test(index_file) eq 0 then return, ''
        lines = read_all_lines(index_file[0])
    endif
    if n_elements(lines) eq 1 and lines[0] eq '' then return, ''

    foreach file, files, ii do begin
        if (strpos(file,'['))[0] eq -1 then if file_test(file) eq 1 then continue
        base_name = fgetbase(file)
        the_files = stregex(lines, base_name, extract=1, fold_case=1)
        index = where(the_files ne '', count)
        if count eq 0 then begin
            ofiles[ii] = ''
            if ~keyword_set(silent) then message, 'No file is found for given pattern: '+base_name+' ...', /continue
            continue
        endif
        the_files = the_files[index]
        the_path = fgetpath(file)
        if ~keyword_set(get_all_match) then begin
            if count gt 1 then the_files = (the_files[sort(the_files)])[-1]
        endif
        nthe_file = n_elements(the_files)
        the_ofiles = strarr(nthe_file)
        for jj=0,nthe_file-1 do begin
            base_name = the_files[jj]
            index = strpos(base_name, '">')
            if index[0] ne -1 then base_name = strmid(base_name,0,index)    ; sometime there are duplicated file names in one line, which causes problem.
            the_ofiles[jj] = join_path([the_path,base_name])
        endfor
        if nthe_file eq 1 then the_ofiles = the_ofiles[0]
        ofiles[ii] = the_ofiles
    endforeach

    if n_elements(ofiles) eq 1 then ofiles = ofiles[0]

    return, ofiles

end
