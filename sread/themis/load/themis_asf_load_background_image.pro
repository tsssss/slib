;+
; Load asf background images to calibrate the raw images.
;-

function themis_asf_load_background_image, input_time_range, site=site, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, return_request=return_request


    errmsg = ''
    retval = !null


;---Handle input.
    sync_threshold = 0
    if n_elements(site) eq 0 then begin
        errmsg = 'No input site ...'
        return, retval
    endif
    sites = themis_read_asi_sites()
    index = where(sites eq site, count)
    if count eq 0 then begin
        errmsg = 'Invalid site: '+site[0]+' ...'
        return, retval
    endif

    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','themis'])
    if n_elements(version) eq 0 then version = 'v01'
    time_range = time_double(input_time_range)


;---Init settings.
    type_dispatch = hash()  ; dummy.

    ; ASF background image.
    valid_range = [time_double('2007'),systime(1)]
    base_name = 'thg_l2_asf_background_image_'+site+'_%Y_%m%d_%H_'+version+'.cdf'
    local_path = [local_root,'thg','asf','asf_background_image',site,'%Y','%m']
    request = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'hour', $
        'extension', fgetext(base_name) )

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        processed_files = list()
        foreach file, request.nonexist_files do begin
            ; Get the predicted files we would get if we run the code.
            file_pattern = (request['pattern'])['local_file']
            the_files = themis_asf_load_background_image_gen_file(file.file_time, site=site, file_pattern=file_pattern, get_name=1)
            ; No data for the given file_time.
            if n_elements(the_files) eq 0 then continue

            ; Determine if we need to run the code by checking if the predicted files are already processed.
            run_code = 0
            foreach the_file, the_files do begin
                if processed_files.where(the_file) ne !null then continue
                processed_files.add, the_file
                run_code = 1
            endforeach

            ; Run the code if the predicted files has not been processed.
            if run_code eq 0 then continue
            the_files = themis_asf_load_background_image_gen_file(file.file_time, site=site, filename=the_files)
        endforeach

        ; Redo the search.
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    endif

    if n_elements(files) eq 0 then return, retval else return, files



end


time_range = time_double(['2015-01-01','2015-02-01'])
secofday = constant('secofday')
dates = make_bins(time_range, secofday)
sites = themis_read_asi_sites()
foreach date, dates do begin
    the_time_range = date+[0,secofday]
    foreach site, sites do begin
        files = themis_asf_load_background_image(the_time_range, site=site)
        store_data, 'thg_'+site+'_asf_bg', delete=1 ; need to clear the memory.
    endforeach
endforeach

end