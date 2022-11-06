;+
; Sync local files from the remote ones.
;
; local_files=. An array of local files (full filename).
; remote_files=. An array of remote files (full url).
; sync_time=. A UT sec. When local files exist, sync only when they are newer than sync_time.
; mtime=. A UT sec. Set the mtime of the local files.
;-

pro sync_file, local_files=local_files, remote_files=remote_files, sync_time=sync_time, mtime=mtime

    errmsg = ''

    local_key = 'file'
    remote_key = 'remote_file'

;---Check inputs.
    nfile = n_elements(local_files)
    if nfile eq 0 then begin
        errmsg = handle_error('No input local files ...')
        return
    endif
    if n_elements(remote_files) ne nfile then remote_files = strarr(nfile)
    ;if n_elements(sync_time) eq 0 then sync_time = systime(1)

;---Gather all (unique) candidates of local files.
    files = hash()
    foreach file, local_files, ii do begin
        if files.haskey(file) then continue
        files[file] = dictionary($
            local_key, local_files[ii], $
            remote_key, remote_files[ii])
    endforeach

;---Check which files need to be synced.
    foreach dict, files, ii do begin
        file = dict[local_key]
        dict['sync'] = ~file_test(file)
        if dict['sync'] eq 1 then continue
        ; File exists, thus do not sync by default.
        if n_elements(mtime) ne 0 then ftouch, file, mtime=mtime
        finfo = file_info(file)
        dict[local_key+'_size'] = finfo.size
        dict[local_key+'_mtime'] = double(finfo.mtime)
        files[ii] = dict
        ; However, sync if sync_time is set and mtime is newer.
        if n_elements(sync_time) eq 0 then continue
        if finfo.mtime le sync_time then continue
        dict['sync'] = 1
        files[ii] = dict
    endforeach
    ; Another pass: do not sync if no remote info.
    foreach dict, files do begin
        if dict[remote_key] ne '' then continue
        dict['sync'] = 0
        files[ii] = dict
    endforeach

;---Sync each file.
    foreach dict, files, ii do begin
        if dict['sync'] eq 0 then continue
        file = dict[local_key]
        remote_file = dict[remote_key]
        download_file, file, remote_file, errmsg=errmsg
        dict['errmsg'] = errmsg
        files[ii] = dict
        if file_test(file) eq 0 then continue
        if n_elements(mtime) ne 0 then ftouch, file, mtime=mtime
    endforeach

end

locals = list()
remotes = list()
; ftp, implicit index file.
locals.add, join_path([homedir(),'Downloads','test','test_ftp.html'])
remotes.add, 'ftp://swarm-diss.eo.esa.int//Level1b/Latest_baselines/MAGx_LR//Sat_C/'
; ftp, explicit index file.
locals.add, join_path([homedir(),'Downloads','test','sa1sum_ftp.txt'])
remotes.add, 'ftp://cdaweb.gsfc.nasa.gov/pub/data/themis/thg/l1/mag/idx/2005/SHA1SUM'
; ftp, data file.
locals.add, join_path([homedir(),'Downloads','test','thg_l1_idx_20050101_v01_ftp.cdf'])
remotes.add, 'ftp://cdaweb.gsfc.nasa.gov/pub/data/themis/thg/l1/mag/idx/2005/thg_l1_idx_20050101_v01.cdf'

; https, implicit index file.
locals.add, join_path([homedir(),'Downloads','test','test_http.html'])
remotes.add, 'https://cdaweb.gsfc.nasa.gov/pub/data/themis/thg/l1/mag/idx/2005/'
; https, explicit index file.
locals.add, join_path([homedir(),'Downloads','test','sa1sum_http.txt'])
remotes.add, 'https://cdaweb.gsfc.nasa.gov/pub/data/themis/thg/l1/mag/idx/2005/SHA1SUM'
; https, data file.
locals.add, join_path([homedir(),'Downloads','test','thg_l1_idx_20050101_v01_http.cdf'])
remotes.add, 'https://cdaweb.gsfc.nasa.gov/pub/data/themis/thg/l1/mag/idx/2005/thg_l1_idx_20050101_v01.cdf'

sync_file, local_files=locals, remote_files=remotes, mtime=time_double('2013-01-01')

end
