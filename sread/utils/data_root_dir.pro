;+
; Handle the root directory for saving data.
;-
;

function data_root_dir, disk

    if n_elements(disk) eq 0 then begin
        case susrhost() of
            'Sheng@rMBP-3.local': disk = 'Research'
            else: disk = 'Research'
        endcase
    endif
    
    ; if disk exists, use it.
    if file_test(disk,/directory) eq 1 then return, disk
    
    ; it may be just the name of the disk, find its full path.
    dir = sdiskdir(disk)
    if file_test(dir,/directory) eq 1 then return, dir
    
    ; in any case, return home directory.
    return, shomedir()

end

print, data_root_dir()
end