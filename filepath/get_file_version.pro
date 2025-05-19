;+
; Get file's version.
;-

function get_file_version, filename

    stem = get_file_stem(filename)
    pos = strpos(stem,'v',reverse_search=1)
    if pos[0] eq -1 then return, ''
    
    version = strmid(stem,pos)
    return, version

end