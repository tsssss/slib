;+
; Save data to one variable in one file. Save settings if provided.
; Will delete the input data from memory.
;
; varname. A string of the var name.
; value=. The data to be saved.
; filename=. A string of the CDF file. Or the cdf_id.
; settings=. A dictionary of the settings for vatt.
; compress=. A number sets the compress level, 0-9?
; cdf_type=. A string specifies the cdf_type.
; save_as_one=. A boolean to save value as a whole, i.e., nrec=1. Used to save metadata.
;-
pro cdf_save_var, varname, value=data, filename=cdf0, settings=settings, $
    compress=compress, cdf_type=cdf_type, $
    save_as_one=save_as_one

    compile_opt idl2
    catch, error
    if error ne 0 then begin
        catch, /cancel
        if input_is_file then cdf_close, cdfid
        errmsg = !error_state.msg
        return
    endif

    ; Check if var is a string.
    if n_elements(varname) eq 0 then begin
        errmsg = handle_error('No input var name ...')
        return
    endif
    the_var = varname[0]

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
            cdf_touch, file
        endif
        cdfid = cdf_open(file)
    endif else cdfid = cdf0
    if keyword_set(compress) then cdf_compression, cdfid, set_gzip_level=compress



;---Save data. Needs to know cdf_type, numelem, dimensions
    has_var = cdf_has_var(the_var, filename=cdfid)
    if has_var then cdf_del_var, the_var, filename=cdfid

    ; Get the cdf_type.
    var_type = keyword_set(cdf_type)? cdf_type: scdffmidltype(size(data[0],/type))
    extra = create_struct(var_type,1)

    ; Get the data size.
    ndim = size(data,n_dimension=1)
    if ndim gt 1 then begin
        permu = shift(findgen(ndim),-1)
        vals = transpose(temporary(data),permu)
    endif else begin
        vals = transpose(temporary(data))
    endelse
    nrec = n_elements(vals)
    data_dims = size(vals,/dimensions)
    data_ndim = n_elements(data_dims)

    ; Strings are special.
    numelem = 1
    if var_type eq 'CDF_CHAR' or var_type eq 'CDF_UCHAR' then begin
        for ii=0, nrec-1 do numelem >= strlen(vals[ii])
    endif

    ; Get the dimensions.
    ; Original data is in [nrec,dims], the convension used in tplot.
    ; However, we transposed it, so vals is in [dims, nrec].
    rec_vary = 1
    if data_ndim eq 1 then rec_vary = 0
    if data_dims[-1] eq 1 then rec_vary = 0
    if keyword_set(save_as_one) then rec_vary = 0
    
    if rec_vary then begin
        if data_ndim gt 1 then begin
            dimensions = data_dims[0:-2]
            ; Scalar needs dimensions to be [].
            if n_elements(dimensions) eq 1 and dimensions[0] eq 1 then dimensions = []
        endif else dimensions = []
    endif else dimensions = data_dims
    
    rec_vary_str = (rec_vary)? 'REC_VARY': 'REC_NOVARY'
    extra = create_struct(rec_vary_str, 1, extra)

    ; Save data.
    if n_elements(dimensions) eq 0 then begin
        tmp = cdf_varcreate(cdfid, the_var, zvariable=1, numelem=numelem, _extra=extra)
    endif else begin
        dimvary = indgen(n_elements(dimensions))+1
        tmp = cdf_varcreate(cdfid, the_var, dimvary, dimensions=dimensions, zvariable=1, numelem=numelem, _extra=extra)
    endelse
    cdf_varput, cdfid, the_var, vals, zvariable=1

    has_setting = isa(settings, 'dictionary')
    if has_setting then cdf_save_setting, settings, filename=cdfid, varname=the_var

    if input_is_file then cdf_close, cdfid


end


file = join_path([homedir(),'test.cdf'])
uts = findgen(1200)
cdf_save_var, 'ut', value=uts, filename=file
vec = findgen(1200,3)
cdf_save_var, 'vec', value=vec, filename=file
end