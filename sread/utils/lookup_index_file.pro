;+
; Look up the local index file for each basename. Find the one of highest order.
; 
; basenames. A string or an array of N base names.
; local_paths. A string or an array of N local full paths.
; index_file. A string of the base name of the index file.
; 
; The index_file and basenames are assumed to be in the same folder.
;=
function lookup_index_file, basenames, local_paths, index_file, silent=silent

    nfile = n_elements(basenames)
    if nfile eq 0 then message, 'No input file ...'
    
    for i=0, nfile-1 do begin
        lines = read_all_lines(join_path([local_paths[i],index_file]))
        if n_elements(lines) eq 1 and lines[0] eq '' then begin
            basenames[i] = ''
            continue
        endif
        files = stregex(lines, basenames[i], /extract)
        idx = where(files ne '', cnt)
        if cnt eq 0 then begin
            if ~keyword_set(silent) then $
                message, 'No file is found for given pattern: '+basenames[i]+' ...', /continue
            return, ''
        endif
        files = files[idx]
        basenames[i] = (cnt eq 1)? files: (files[sort(files)])[-1]
    endfor
    
    return, basenames

end