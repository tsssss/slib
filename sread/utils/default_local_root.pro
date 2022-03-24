;+
; Handle the root directory for saving data.
;-
;

function default_local_root, disk

    if n_elements(disk) eq 0 then begin
        disk = 'data'
        if susrhost() eq 'kersten@xwaves7.space.umn.edu' then disk = '/Volumes/UserA/user_volumes/kersten/data_external'
    endif
    
    ; if disk exists, use it.
    if file_test(disk,directory=1,noexpand_path=1) eq 1 then return, disk
    
    ; it may be just the name of the disk, find its full path.
    dir = diskdir(disk)
    if file_test(dir,directory=1) eq 1 then return, dir
    
    ; in any case, return home directory.
    lprmsg, 'Use the home directory as the root directory ...'
    return, homedir()

end

print, default_local_root()
end
