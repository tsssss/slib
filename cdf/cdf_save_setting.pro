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

pro cdf_save_one_setting, key, val, cdfid=cdfid, varname=varname

    on_error, 2     ; return to caller.

    ; Determine scope: g or v.
    global_scope = ~n_elements(varname)
    ; Do nothing if scope is v but var does not exist.
    if ~global_scope then if ~cdf_has_var(varname, filename=cdfid) then return

    ; String is special.
    if size(val,/type) eq 7 then foreach tmp, val, ii do if val[ii] eq '' then val[ii] = ' '

    if global_scope then begin
        if ~cdf_attexists(cdfid, key) then begin
            entry = cdf_attcreate(cdfid, key, global_scope=1)
        endif else begin
            entry = cdf_attnum(cdfid, key)
        endelse
        foreach tval, val, ii do cdf_attput, cdfid, key, ii, tval
    endif else begin
        if ~cdf_attexists(cdfid, key) then begin
            tmp = cdf_attcreate(cdfid, key, variable_scope=1)
        endif
        varinq = cdf_varinq(cdfid, varname)
        iszvar = varinq.is_zvar
        cdf_attput, cdfid, key, varname, val, zvariable=iszvar
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
        foreach key, dict.keys() do cdf_save_one_setting, key, dict[key], cdfid=cdfid, varname=varname
    endif else begin
        keys = dict
        if n_elements(keys) eq 1 then begin
            cdf_save_one_setting, keys[0], vals, cdfid=cdfid, varname=varname
        endif else begin
            if n_elements(keys) ne n_elements(vals) then begin
                errmsg = handle_error(cdfid=cdfid, 'Inconsistent key and value ...')
                return
            endif
            foreach key, keys, ii do cdf_save_one_setting, key, vals[ii], cdfid=cdfid, varname=varname
        endelse
    endelse

    if input_is_file then cdf_close, cdfid


end

file = join_path([shomedir(),'test.cdf'])
;cdf_save_setting, 'Author3', 'Sheng', filename=file
;cdf_save_setting, 'Author3', ['Sheng','Tian'], filename=file
;cdf_save_setting, dictionary('Author3', 'Sheng Tian'), filename=file
cdf_save_setting, 'foo', ['hehe','haha'], filename=file, varname='po_rbmag_t89'
cdf_save_setting, 'foo', ['doudou','lele'], filename=file, varname='po_dbmag_t89'
end
