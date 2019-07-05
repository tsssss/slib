;+
; Download a given URL and save it to the given local full file name.
;
; local_file. A string of the local full file name.
; remote_file. A string of the remote URL.
;-
pro download_file, local_file, remote_file, errmsg=errmsg

    errmsg = ''
    catch, errorstatus
    if errorstatus ne 0 then begin
        catch, /cancel
        errmsg = handle_error(!error_state.msg)
        return
    endif

    lprmsg, 'Downloading '+remote_file+' ...'

    url_info = parse_url(remote_file)
    scheme = strlowcase(url_info.scheme)
    if scheme eq 'ftp' or scheme eq 'sftp' then begin
        download_ftp_file, local_file, remote_file, errmsg=errmsg
        return
    endif
    if scheme eq 'http' or scheme eq 'https' then begin
        download_http_file, local_file, remote_file, errmsg=errmsg
    endif

    download_http_file, local_file, 'http://'+remote_file, errmsg=errmsg
    lprmsg, 'Saved to '+local_file+' ...'

end


remote_file = 'https://themis.ssl.berkeley.edu/data/themis/tha/l2/efi/2014/tha_l2_efi_20140101_v01.cdf'
;remote_file = 'http://themis.ssl.berkeley.edu/data/rbsp/rbspb/l1/vb1/2015/rbspb_l1_vb1_20150309_v02.cdf'
local_file = join_path([homedir(),'Downloads',fget_base(remote_file)])

download_file, local_file, remote_file
end
