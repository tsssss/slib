;+
; To achieve what mms_get_state_data does and save the data to CDFs.
; 
; id=. 'defeph','defatt'
;-

function mms_ld_state_data, input_time_range, probe=probe, id=mode_str, $
    errmsg=errmsg

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'mms'])
    if n_elements(version) eq 0 then version = 'v01'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse
    ; The data for a certain day may span the current and previous days.
    data_time_range = minmax(break_down_times(time_range+[-1,1]*constant('secofday'), 'day'))
    dates = time_string(data_time_range, tformat='YYYY-MM-DD')

    public = 1
    if n_elements(mode_str) eq 0 then mode_str = 'defeph'
    local_path = join_path([local_root,'mms'+probe,'state',mode_str,'%Y'])
    ancillary_file_info = mms_get_ancillary_file_info(sc_id='mms'+probe, $
        product=mode_str, start_date=dates[0], end_date=dates[1], public=public)
    remote_file_info = mms_parse_json(ancillary_file_info)
    local_files = list()
    file_times = list()
    foreach info, remote_file_info do begin
        file_time = time_double(info.startdate,tformat='YYYY-MM-DDT00:00:00')
        local_dir = apply_time_to_pattern(local_path,file_time)
        base = info.filename
        local_file = join_path([local_dir,base])
        if file_test(local_file) then begin
            local_files.add, local_file
            file_times.add, file_time
            continue
        endif else begin
            if file_test(local_dir) eq 0 then file_mkdir, local_dir
            status = get_mms_ancillary_file(filename=base, local_dir=local_dir, public=public)
            if status eq 0 then begin
                local_files.add, local_file
                file_times.add, file_time
            endif
        endelse
    endforeach

    file_times = file_times.toarray()
    local_files = local_files.toarray()
    index = sort(file_times)
    local_files = local_files[index]
    return, local_files

end


tr = ['2015-09-01','2015-09-02']
probe = '1'
print, mms_ld_state_data(tr, probe=probe, id='defeph')
print, mms_ld_state_data(tr, probe=probe, id='defatt')
end