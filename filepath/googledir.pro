;+
; Return the Google Drive directory for file streaming.
;-

function googledir, errmsg=errmsg
    errmsg = ''
    retval = !null

    case !version.os of
        'Win32': google_name = 'Google Drive File Stream'
        'darwin': google_name = 'GoogleDrive'
        'linux': ; do not support yet.
        else: begin
            errmsg = handle_error('Unknown OS ...')
            return, retval
        end
    endcase

    the_dir = join_path([diskdir(google_name),'My Drive'])
    return, the_dir

end

print, googledir()
end
