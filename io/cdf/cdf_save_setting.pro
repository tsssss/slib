;+
; Save global or varialbe settings.
; To save global settings (gatt):
;   cdf_save_setting, key, val, filename=file
;   cdf_save_setting, keys, vals, filename=file
;   cdf_save_setting, dict, filename=file
; To save variable settings (vatt):
;   cdf_save_setting, key, val, filename=file, varname=var
;   ...
; One entry only holds one scalar value for gatt, can hold an array for vatt.
;-

pro cdf_save_dict_setting, name, dict, cdfid=cdfid, varname=varname

    on_error, 0     ; stop here.

    ; Convert structure to dict.
    if size(dict,type=1) eq 8 then dict = dictionary(dict)
    
    foreach key, dict.keys() do begin
        the_key = name+'@'+key
        the_val = dict[key]
        the_type = size(the_val,type=1)
        if the_type eq 8 or the_type eq 11 then begin
            routine = 'cdf_save_dict_setting'
        endif else begin
            routine = 'cdf_save_val_setting'
        endelse
        call_procedure, routine, the_key, the_val, cdfid=cdfid, varname=varname
    endforeach
    
end

pro cdf_save_val_setting, key, val, cdfid=cdfid, varname=varname

    on_error, 0     ; stop here.
    min_nrec = 3

    ; Determine scope: g or v.
    global_scope = ~n_elements(varname)
    ; Do nothing if scope is v but var does not exist.
    if ~global_scope then if ~cdf_has_var(varname, filename=cdfid) then return

    ; String is special.
    type = size(val,type=1)
    if type eq 7 then foreach tmp, val, ii do if val[ii] eq '' then val[ii] = ' '

    if global_scope then begin
        if ~cdf_attexists(cdfid, key) then begin
            entry = cdf_attcreate(cdfid, key, global_scope=1)
        endif else begin
            entry = cdf_attnum(cdfid, key)
        endelse
        foreach tval, val, ii do begin
            cdf_attput, cdfid, key, ii, tval
        endforeach
    endif else begin
        if ~cdf_attexists(cdfid, key) then begin
            tmp = cdf_attcreate(cdfid, key, variable_scope=1)
        endif
        varinq = cdf_varinq(cdfid, varname)
        iszvar = varinq.is_zvar
        ; cdf_attput cannot write complex number directly.
        if type eq 6 or type eq 9 then begin
            complex_val = dictionary('real',real_part(val),'imaginary',imaginary(val))
            cdf_save_dict_setting, key, complex_val, cdfid=cdfid, varname=varname
        endif else begin
            nrec = n_elements(val)
            if nrec gt min_nrec and size(val,type=1) ne 7 then begin
                ; If not string or string array, save array to a separate variable.
                the_var = varname+'@'+key+'#value'
                cdf_save_var, the_var, value=val, filename=cdfid, save_as_one=1, settings=dictionary('var_type','vatt_data')
                cdf_attput, cdfid, key, varname, the_var, zvariable=iszvar
            endif else begin
                cdf_attput, cdfid, key, varname, val, zvariable=iszvar
            endelse
        endelse
    endelse
    
end

pro cdf_save_setting, dict, vals, filename=cdf0, varname=varname

    ; Check if given file is a cdf_id or filename.
    if n_elements(cdf0) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return
    endif
    input_is_file = size(cdf0, /type) eq 7
    if input_is_file then begin
        file = cdf0
        path = fgetpath(file)
        if file_test(file) eq 0 then begin
            if file_test(path,/directory) eq 0 then file_mkdir, path
            cdfid = cdf_create(file)
        endif else cdfid = cdf_open(file)
    endif else cdfid = cdf0


    if n_params() eq 1 then begin
        the_dict = dict
    endif else begin
        if n_elements(keys) eq 1 then begin
            the_dict = dictionary(keys[0], vals)
        endif else begin
            if n_elements(keys) ne n_elements(vals) then begin
                if input_is_file then cdf_close, cdfid
                errmsg = handle_error('Inconsistent key and value ...')
                return
            endif else begin
                the_dict = dictionary(keys, vals)
            endelse
        endelse
    endelse
    foreach key, the_dict.keys() do begin
        val = the_dict[key]
        the_type = size(val,type=1)
        if the_type eq 8 or the_type eq 11 then begin
            routine = 'cdf_save_dict_setting'
        endif else begin
            routine = 'cdf_save_val_setting'
        endelse
        call_procedure, routine, key, val, cdfid=cdfid, varname=varname
    endforeach

    if input_is_file then cdf_close, cdfid

end

file = join_path([shomedir(),'test.cdf'])
;cdf_save_setting, 'Author3', 'Sheng', filename=file
;cdf_save_setting, 'Author3', ['Sheng','Tian'], filename=file
;cdf_save_setting, dictionary('Author3', 'Sheng Tian'), filename=file
cdf_save_setting, 'foo', ['hehe','haha'], filename=file, varname='po_rbmag_t89'
cdf_save_setting, 'foo', ['doudou','lele'], filename=file, varname='po_dbmag_t89'
end
