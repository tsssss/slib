;+
; Read pitch angle distributions.
;-

function mms_read_pad_kev_ele, input_time_range, id=datatype, probe=probe, species=species, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request

end




function mms_read_pad_kev, input_time_range, id=datatype, probe=probe, species=species, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request

    if n_elements(species) eq 0 then species = 'e'


    if species eq 'e' then begin
        return, mms_read_pad_kev_ele(input_time_range, id=datatype, probe=probe, species=species, $
            print_datatype=print_datatype, errmsg=errmsg, $
            local_files=files, file_times=file_times, version=version, $
            local_root=local_root, remote_root=remote_root, $
            return_request=return_request)
    endif else begin
;        return, mms_read_pad_kev_ion(input_time_range, id=datatype, probe=probe, species=species, $
;            print_datatype=print_datatype, errmsg=errmsg, $
;            local_files=files, file_times=file_times, version=version, $
;            local_root=local_root, remote_root=remote_root, $
;            return_request=return_request)
    endelse

end

tr = time_double(['2016-08-04','2016-08-05'])
probe = '2'

ele_var = mms_read_pad_kev(tr, probe=probe, species='e')
stop
