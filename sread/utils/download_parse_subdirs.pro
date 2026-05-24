
function download_parse_subdirs, index_file, errmsg=errmsg
    compile_opt idl2
    errmsg = ''
    retval = !null

    lines = read_all_lines(index_file)

;---Find parent dir
    parent_dir_str = 'alt="\[PARENTDIR\]"'
    i0 = where(stregex(lines, parent_dir_str) ne -1, count)
    if count gt 1 then begin
        errmsg = 'Inconsistency ...'
        return, retval
    end
    i0 = i0[0]
    nline = n_elements(lines)
    for ii=i0+1,nline-1 do begin
        if lines[ii] eq "</table>" then break
    endfor
    if ii eq nline then begin
        errmsg = 'Inconsistency ...'
        return, retval
    end

    ; No subfiles.
    i1 = ii-1
    if i0 eq i1 then return, retval

;---Find subdirs and files.
    lines = lines[i0+1:i1]
    dir_regex = 'a href="([^"]+)"'
    tmp = stregex(lines, dir_regex, extract=1, subexpr=1)
    subfiles = reform(tmp[1,*])
    return, subfiles

end