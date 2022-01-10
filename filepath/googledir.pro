;+
; Return the Google Drive directory for file streaming.
;-

function googledir, errmsg=errmsg
    errmsg = ''
    retval = !null

    case !version.os of
        'Win32': google_name = 'Google Drive'
        'darwin': google_name = 'GoogleDrive'
        'linux': ; do not support yet.
        else: begin
            errmsg = handle_error('Unknown OS ...')
            return, retval
        end
    endcase

    the_dir = join_path([diskdir(google_name),'My Drive'])
    if susrhost() eq 'Sheng Tian@DESKTOP-2N7I6Q7' then the_dir = 'D:\tian\googledrive'
    return, the_dir

end

print, googledir()
end
