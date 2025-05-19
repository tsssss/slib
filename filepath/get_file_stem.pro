function get_file_stem, filename, extension=ext

    if n_elements(ext) eq 0 then ext = get_file_extension(filename)
    base = file_basename(filename)
    pos = strpos(base,ext)
    if pos[0] eq -1 then return, base
    return, strmid(base,0,pos[0]-1)

end