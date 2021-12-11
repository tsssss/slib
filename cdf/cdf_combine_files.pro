;+
; Combine data in given files and save them to an output file.
;-

pro cdf_combine_files, in_files, to=out_file

    if n_elements(in_files) eq 0 then return
    if n_elements(out_file) eq 0 then return
    if file_test(out_file) eq 1 then file_delete, out_file

    skeleton = cdf_read_skeleton(in_files[0])
    cdf_save_setting, skeleton.header, filename=out_file
    
;---Distinguish data and metadata.
    data_vars = list()
    meta_vars = list()
    foreach var_info, skeleton.var do begin
        var_setting = var_info.setting
        the_var = var_info.name
        if var_setting.haskey('VAR_TYPE') then begin
            var_type = var_setting['VAR_TYPE']
            if var_type eq 'metadata' then begin
                if meta_vars.where(the_var) eq !null then meta_vars.add, the_var
            endif else begin
                if data_vars.where(the_var) eq !null then data_vars.add, the_var
            endelse
        endif else begin
            if meta_vars.where(the_var) eq !null then meta_vars.add, the_var
        endelse
    endforeach
    
    
;---Loop through each var.
    foreach var_info, skeleton.var do begin
        var_setting = var_info.setting
        the_var = var_info.name
        print, 'Combining '+the_var+' ...'

        val = []
        if data_vars.where(the_var) ne !null then begin
            foreach in_file, in_files do begin
                val = [val,cdf_read_var(the_var, filename=in_file)]
            endforeach
        endif
        if meta_vars.where(the_var) ne !null then begin
            in_file = in_files[0]
            val = cdf_read_var(the_var, filename=in_file)
        endif
        
        if n_elements(val) ne 0 then begin
            cdf_save_var, the_var, value=val, filename=out_file
        endif
        if n_elements(var_setting) ne 0 then begin
            cdf_save_setting, var_setting, varname=the_var, filename=out_file
        endif
    endforeach
    
end
