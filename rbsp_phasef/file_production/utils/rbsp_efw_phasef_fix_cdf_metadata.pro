;+
; Fix if a metadata is not saved as 1 rec in a cdf.
;-
pro rbsp_efw_phasef_fix_cdf_metadata, files, path=path

    if n_elements(path) ne 0 then begin
        if file_test(path,/directory) then begin
            files = file_search(join_path([path,'*.cdf']))
        endif
    endif
    nfile = n_elements(files)
    if nfile eq 0 then return

    foreach file, files do begin
        skt = cdf_read_skeleton(file)
        foreach var_info, skt.var do begin
            vatt = var_info.setting
            the_var = var_info.name
            
            ; Get vatt.
            if ~vatt.haskey('VAR_TYPE') then continue
            
            ; Only deal with metadata.
            var_type = vatt['VAR_TYPE']
            if var_type ne 'metadata' then continue
            
            ; No need to fix if nrec=1
            if var_info.maxrec eq 1 then continue

            ; Need to fix.
            data = cdf_read_var(the_var, filename=file)
            cdf_del_var, the_var, filename=file
            cdf_save_var, the_var, value=data, settings=vatt,$
                filename=file, save_as_one=1
        endforeach
    endforeach

end

path = '/Volumes/data/rbsp/rbspa/l1/vb1_split/2013'
rbsp_efw_phasef_fix_cdf_metadata, path=path
end