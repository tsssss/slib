;+
; Create an empty file if it does not exist, and change the mtime.
;
; file. A string of the file.
; mtime=. A double of mtime in UT sec.
;-

pro ftouch, file, mtime=mtime0, errmsg=errmsg

    errmsg = ''

    if n_elements(file) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return
    endif

    ; Check if file exists, and the current OS.
    flag = file_test(file)    ; Cannot handle directory.
    iswin = !version.os_family eq 'Windows'

    ; Create an empty file if it does not exist.
    if flag eq 0 then begin
        path = fgetpath(file)
        if file_test(path,/directory) eq 0 then file_mkdir, path

        case iswin of
            0: cmd = 'touch "'+file+'"'
            1: cmd = 'type NUL > "'+file+'"'
        endcase
        spawn, cmd, msg, errmsg
    endif

    ; Confirm the file exists.
    if file_test(file) eq 0 then begin
        errmsg = handle_error('Fail to create the file '+file+' ...')
        return
    endif

    ; Change the mtime.
    if n_elements(mtime0) eq 0 then return
    ; change ut to local time.
    mtime = mtime0+stzinfo(mtime0)*3600d
    case iswin of
        0: cmd = 'touch -cmt '+stodate(mtime,'%Y%m%d%H%M.%S')+' "'+file+'"'
        1: cmd = '%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -Command $a = Get-Date -Date \"'+$
            stodate(mtime,'%Y-%m-%d %H:%M:%S')+$
            '\" ;(ls \"'+file+'\").LastWriteTime = $a'
    endcase
    spawn, cmd, msg, errmsg

end

ftouch, homedir()+'/test_file.txt', mtime = time_double('1999-01-01')
end
