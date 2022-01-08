;+
; Return the absolute path of given hard disk drive name.
;
; disk. A string specifies the name of the hard disk drive.
; trailing_slash. A boolean, set it to add a trailing slash.
;-

function diskdir, disk, trailing_slash = trailing_slash, errmsg=errmsg

    errmsg = ''
    retval =  homedir()

    if n_elements(disk) eq 0 then begin
        errmsg = handle_error('No input hard disk ...')
        return, retval
    endif

    case !version.os of
        'linux': diskdir = join_path(['','media',disk])
        'darwin': diskdir = join_path(['','Volumes',disk])
        'Win32': begin
            spawn, '%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -Command Get-WmiObject Win32_LogicalDisk', outputs
            idx = where(stregex(outputs, disk) ne -1, cnt)  ; hitted disk info.
            if cnt eq 0 then begin
                errmsg = handle_error('No such disk: '+disk+' ...')
                return, retval
            endif
            if cnt gt 1 then message, 'more than 1 disk found ...', /continue
            idx1 = idx[0]               ; use the first disk info.
            idx = where(outputs eq '')  ; find disk info blocks.
            tmp = (where(idx ge idx1))[0]
            outputs = outputs[idx[tmp-1]:idx[tmp]]    ; locate the block.
            idx = where(stregex(outputs, 'VolumeName') ne -1)
            the_disk = (strsplit(outputs[idx],' ',/extract))[2]
            if strlowcase(the_disk) ne strlowcase(disk) then begin
                errmsg = handle_error('No such disk: '+disk+' ...')
                return, retval
            endif
            idx = where(stregex(outputs, 'DeviceID') ne -1)
            diskdir = strupcase(strmid(strtrim(outputs[idx],2),1,/reverse_offset))
            end
        else: begin
            errmsg = handle_error('Unkown OS ...')
            return, retval
            end
    endcase

    if ~file_test(diskdir, /directory) then begin
        errmsg = handle_error('No such drive: '+diskdir+' ...')
        return, retval
    endif
    if keyword_set(trailing_slash) then diskdir += '/'
    return, diskdir[0]

end

print, diskdir('Research')
end
