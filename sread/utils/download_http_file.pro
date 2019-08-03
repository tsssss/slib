;+
; Download a given URL and save it to the given local full file name.
;
; local_file. A string of the local full file name.
; remote_file. A string of the remote URL.
;-
function download_http_file_callback_time2string, sec0
    time = sec0
    sec = time mod 60
    time = floor(time/60)
    min = time mod 60
    time = floor(time/60)
    hr = time mod 24
    return, strjoin(string([hr,min,sec],format='(I02)'),':')
end

function download_http_file_callback, status, progress, data

    ; 8+4, 5+4, 10+4, 8+4, 8+4
    format = '(A, T12, A, T21, A, T35, A, T47, A, T59)'

    tstep = 5d  ; second.
    tnow = systime(/second)
    duration = tnow-*data.current_time

    if *data.started eq 0 then begin
        *data.started = 1
        msg = string(' Total ','Perc%','Down.Speed','T.Spent',' T.Left ', format=format)
        lprmsg, msg
        msg = string(data.fsize_string, $
            string(0,format='(F5.1)'), $
            string(0,format='(F5.1)')+' kB/s', $
            string('00:00:00'), $
            string('--:--:--'), $
            format=format)
        lprmsg, msg
    endif

    if duration ge tstep then begin
        speed = (progress[2]-*data.current_size)/duration    ; kB/s.
        units = ['B/s','kB/s','MB/s','GB/s','TB/s']
        foreach unit, units do if speed lt 1000 then break else speed *= 1e-3
        percent = double(progress[2])/data.total_fsize
        tspent = tnow-data.start_time
        tleft = tspent/percent*(1-percent)

        msg = string(data.fsize_string, $
            string(percent*100,format='(F5.1)'), $
            string(speed,format='(F5.1)')+' '+unit, $
            download_http_file_callback_time2string(tspent), $
            download_http_file_callback_time2string(tleft), $
            format=format)

        lprmsg, msg
        *(data.current_time) = tnow
        *(data.current_size) = progress[2]
    endif

    return, 1
end

pro download_http_file, local_file, remote_file, errmsg=errmsg
    
    errmsg = ''
    catch, errorstatus
    if errorstatus ne 0 then begin
        catch, /cancel
        errmsg = handle_error(!error_state.msg)
        return
    endif

    lprmsg, 'Downloading '+remote_file+' ...'

    info = get_remote_info(remote_file)
    fsize = info.size
    units = ['B','kB','MB','GB','TB']
    foreach unit, units do if fsize lt 1000 then break else fsize *= 1e-3

    locdir = file_dirname(local_file)
    if file_test(locdir,/directory) eq 0 then file_mkdir, locdir

    oo = obj_new('IDLnetUrl')
    oo->setproperty, callback_function='download_http_file_callback', $
        callback_data={ $
            total_fsize: info.size, $
            fsize_string: string(fsize,format='(F5.1)')+' '+unit, $
            start_time: systime(/second), $
            current_time: ptr_new(systime(/second)), $
            current_size: ptr_new(0ull), $
            started: ptr_new(0)}

    file = oo->get(filename=local_file, url=remote_file)
    obj_destroy, oo

    if info.mtime ne 0 then ftouch, local_file, mtime=info.mtime
    lprmsg, 'Saved to '+local_file+' ...'

end


remote_file = 'http://themis.ssl.berkeley.edu/data/themis/tha/l2/efi/2014/tha_l2_efi_20140101_v01.cdf'
;remote_file = 'http://themis.ssl.berkeley.edu/data/rbsp/rbspb/l1/vb1/2015/rbspb_l1_vb1_20150309_v02.cdf'
local_file = join_path([homedir(),'Downloads',fgetbase(remote_file)])

remote_file = 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp/rbspa/l3/ect/hope/pitchangle/rel04/2013/'
local_file = 'e:/data/rbsp/rbspa/hope/level3/pa_rel04/2013/remote_index.html'

download_http_file, local_file, remote_file
end
