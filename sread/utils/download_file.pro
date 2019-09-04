;+
; Download a given URL and save it to the given local full file name.
;
; local_file. A string of the local full file name.
; remote_file. A string of the remote URL.
;-

function download_file_callback, status, progress, data
    compile_opt idl2, hidden
    ; Exceptions in this code would normally be caught in spd_download_file.
    ; However, if the download is not canceled by returning 0 here then the
    ; file will remain locked by idl (windows).  The flag alerts the error
    ; handler that the cancel was actually an error.
    catch, error
    if error ne 0 then begin
        catch, /cancel
        help, /last_message
        if isa(data,'struct') then *(data.error) = 1b
        return, 0
    endif


    ;time in sec between messages
    delay = 5d  ; second.
    elapsed = systime(/sec) - *(data.msg_time)

    if elapsed ge delay then begin
        ;if progress data is valid then print the total progress,
        if progress[0] then begin
            speed = (progress[2]-*(data.msg_data))/elapsed
            units = ['B/s','kB/s','MB/s','GB/s','TB/s']
            foreach unit, units do if speed lt 1000 then break else speed *= 1e-3
            speed = string(speed,format='(F5.1)')+' '+unit
            speed = extend_string(speed,length=10)

            ;if total size is unknown then only print amount transferred and speed
            if progress[1] eq 0 then begin
                complete = progress[2]
                units = ['B','kB','MB','GB','TB']
                foreach unit, units do if complete lt 1000 then break else complete *= 1e-3
                complete = string(complete,format='(F5.1)')+' '+unit
            endif else begin
                complete = 100.*progress[2]/progress[1]
                complete = string(complete,format='(F5.1)')+'%'
            endelse
            complete = extend_string(complete,length=8)
            msg = ' '+complete+'  '+speed
        endif else begin
            msg = '  '+status
        endelse

        *(data.msg_time) = systime(/sec)
        *(data.msg_data) = progress[2]
        lprmsg, msg
    endif

    return, 1
end

pro download_file, local_file, remote_file, errmsg=errmsg

    errmsg = ''
    catch, errorstatus
    if errorstatus ne 0 then begin
        catch, /cancel
        errmsg = handle_error(!error_state.msg)
        return
    endif

    local_file = local_file[0]
    remote_file = remote_file[0]
    lprmsg, 'Downloading '+remote_file+' ...'
    local_path = fgetpath(local_file)
    if file_test(local_path,/directory) eq 0 then file_mkdir, local_path

;stop
;    tmp = spd_download_file(url=remote_file, filename=local_file)
;stop

;---Prepare header.
    headers = ['User-Agent: IDL']
    url_info = parse_url(remote_file)

    net = obj_new('idlneturl')
    net->setproperty, $
        headers=headers, $
        url_scheme=url_info.scheme, $
        url_host=url_info.host, $
        url_path=url_info.path, $
        url_query=url_info.query, $
        url_port=url_info.port, $
        url_username=url_info.username, $
        url_password=url_info.password
    net->setproperty, callback_function='download_file_callback', $
        callback_data={ $
            net_object: net, $
            msg_time: ptr_new(systime(/sec)), $
            msg_data: ptr_new(0ul), $
            error: ptr_new(0b)}
    file = net->get(filename=local_file, url=remote_file)
    obj_destroy, net
    
    
    lprmsg, 'Saved to '+local_file+' ...'

end

urls = list()
; https.
;urls.add, 'https://cdaweb.sci.gsfc.nasa.gov/pub/data/rbsp/rbspa/l3/efw/2016/rbspa_efw-l3_20160101_v01.cdf'
;urls.add, 'https://cdaweb.sci.gsfc.nasa.gov/pub/data/rbsp/rbspa/l1/efw/mscb1/2019/rbspa_l1_mscb1_20190308_v02.cdf'
; http.
urls.add, 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp/rbspa/l3/emfisis/magnetometer/4sec/gsm/2012/test'
;urls.add, 'http://themis.ssl.berkeley.edu/data/rbsp/rbspb/l1/vb1/2015/rbspb_l1_vb1_20150309_v02.cdf'

; ftp.
;urls.add, 'ftp://swarm-diss.eo.esa.int/Level1b/Latest_baselines/MAGx_LR/Sat_C/SW_OPER_MAGC_LR_1B_20131126T000000_20131126T235959_0505.CDF.ZIP'

local_path = join_path([homedir(),'Downloads'])
foreach url, urls do begin
    remote_file = fgetpath(url)+'/'
    base_name = fgetbase(url)+'.html'
    local_file = join_path([local_path,base_name])
    download_file, local_file, remote_file
    if file_test(local_file) eq 0 then begin
        lprmsg, 'Download failed ...'
        stop
    endif else lprmsg, 'Download is complete ...'
endforeach

stop
foreach url, urls do begin
    remote_file = url
    base_name = fgetbase(remote_file)
    local_file = join_path([local_path,base_name])
    download_file, local_file, remote_file
    if file_test(local_file) eq 0 then begin
        lprmsg, 'Download failed ...'
        stop
    endif else lprmsg, 'Download is complete ...'
endforeach

end