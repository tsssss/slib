;+
; Download survey movie.
;-

function  themis_asi_download_survey_movie, input_time_range, remote_root=remote_root, local_root=local_root

    if n_elements(remote_root) eq 0 then remote_root = 'https://data.phys.ucalgary.ca/sort_by_instrument/all_sky_camera/THEMIS/rt-mosaic/mp4'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'themis','thg','survey_movie'])
    time_range = time_double(input_time_range)

    local_path = [local_root,'%Y','%m']
    remote_path = [remote_root,'%Y','%m']
    valid_range = ['2000']
    base_name = 'themis_rt_mosaic_[0-9-]*.mp4'
    request = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'month', $
        'extension', fgetext(base_name) )

    file_times = break_down_times(time_range, 'month')
    index = where(file_times ge valid_range[0], count)
    if count eq 0 then return, ''
    file_times = file_times[index]
    files = list()
    foreach file_time, file_times do begin
        remote_index_file = apply_time_to_pattern(request.pattern.remote_index_file, file_time)
        local_index_file = apply_time_to_pattern(request.pattern.local_index_file, file_time)
        if file_test(local_index_file) eq 0 then download_file, local_index_file, remote_index_file
        lines = read_all_lines(local_index_file)
        the_files = stregex(lines, base_name, extract=1, fold_case=1)
        index = where(the_files ne '', count)
        if count eq 0 then continue
        the_files = the_files[index]
        
        remote_path = remote_index_file
        local_path = fgetpath(local_index_file)
        foreach file, the_files do begin
            remote_file = join_path([remote_path,file])
            local_file = join_path([local_path,file])
            download_file, local_file, remote_file
        endforeach
        files.add, local_file
    endforeach
    files = files.toarray()
    
    
    if n_elements(files) eq 0 then return, '' else return, files

end

time_range = ['2012','2020']
files = themis_asi_download_survey_movie(time_range)
end