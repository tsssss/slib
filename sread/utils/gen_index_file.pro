;+
; Save the index file to disk as an html file.
;
; finfos. A list of structure, each element is the return value of file_info.
; filename=. A string of html file for exporting the index file.
; delete_empty_folder=. A boolean, set to remove empty folder.
;-

pro gen_index_file_per_file, the_file, extension=extension, $
    delete_empty_folder=delete_empty_folder

    path = fgetpath(the_file)
    base = fgetbase(the_file)
    if file_test(path,/directory) eq 0 then file_mkdir, path
    if file_test(path,/directory) eq 0 then return

;---Search for files for the given extension.
    pattern = '*'
    if keyword_set(extension) then pattern += ('.'+fgetext('.'+extension))
    files = file_search(join_path([path,pattern]),/fold_case)
    finfos = list()
    foreach file, files do begin
        ; Do not include the index file itself.
        if file eq '' then continue
        if file eq the_file then continue
        finfos.add, file_info(file)
    endforeach
    nfile = finfos.count()
    if nfile eq 0 then begin
        if keyword_set(delete_empty_folder) then file_delete, the_file, /allow_nonexistent
        return
    endif

;---Construct the body.
    tab = '  '
    files = strarr(nfile+1)
    mtimes = strarr(nfile+1)
    fsizes = strarr(nfile+1)
    files[0] = 'Name'
    mtimes[0] = 'Last modified'
    fsizes[0] = 'Size'
    foreach finfo, finfos, ii do begin
        files[ii+1] = fgetbase(finfo.name)
        mtimes[ii+1] = time_string(double(finfo.mtime),tformat='DD-MTH-YYYY hh:mm')
        fsizes[ii+1] = string(finfo.size,format='(I0)')
    endforeach
    files = extend_string(files)
    mtimes = extend_string(mtimes)
    fsizes = extend_string(fsizes)

    body = list()
    for ii=0, nfile do begin
        line = files[ii]+tab+mtimes[ii]+tab+fsizes[ii]
        body.add, line
    endfor
    body.add, '<pre>', 0
    body.add, '</pre>'

    title = 'Index of '+path
    body.add, '<h1>'+title+'</h1>', 0
    body.add, '<head><title>'+title+'</title></head>', 0
    body.add, '<html>', 0
    body.add, '</html>'

    openw, lun, the_file, /get_lun
    foreach line, body do printf, lun, line
    free_lun, lun

end


pro gen_index_file, files, extension=extension, sync_time=sync_time, mtime=mtime, delete_empty_folder=delete_empty_folder

    errmsg = ''

    nfile = n_elements(files)
    if nfile eq 0 then begin
        errmsg = handle_error('No output file name is set ...')
        return
    endif

;---Gather all (unique) candidates of local files.
    uniq_files = unique(files)
    foreach file, uniq_files, ii do begin
        gen_index_file_per_file, file, extension=extension, delete_empty_folder=delete_empty_folder
        if file_test(file) eq 0 then continue
        if n_elements(mtime) ne 0 then ftouch, file, mtime=mtime
    endforeach

end

gen_index_file, join_path([homedir(),'index.html']);, extension='.dat'
end
