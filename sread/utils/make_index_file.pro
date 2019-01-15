;+
; Make an index file for the files in the current folder.
;-

pro make_index_file, index_ffn, errmsg=errmsg

    dir = file_dirname(index_ffn)
    if file_test(dir,/directory) eq 0 then begin
        errmsg = handle_error('No such directory: '+dir+' ...')
        return
    endif
    if file_test(index_ffn) then file_delete, index_ffn
    files = file_search(dir+'/*')
    nfile = n_elements(files)
    flags = bytarr(nfile)
    for i=0, nfile-1 do flags[i] = file_test(files[i],/directory)
    index = where(flags eq 0, nfile)
    
    ; No file, create an empty index file.
    if nfile eq 0 then begin
        stouch, index_ffn
        return
    endif
    
    tab = '     '
    files = files[index]
    lines = strarr(nfile)
    for i=0, nfile-1 do begin
        finfo = file_info(files[i])
        basename = file_basename(files[i])
        strmtime = stodate(finfo.mtime, '%Y-%m-%d/%H:%M:%S')
        strfsize = string(finfo.size, format='(A)')
        lines[i] = string(strmtime+tab+strfsize+tab+basename)
    endfor
    
    openw, lun, index_ffn, /get_lun
    printf, lun, 'Index file for '+dir
    printf, lun, 'Last-Modified Time (UT) / File size in KB / File name'
    printf, lun, lines
    free_lun, lun

end

index = shomedir()+'/test_index.txt'
make_index_file, index
end