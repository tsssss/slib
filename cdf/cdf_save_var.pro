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
; save_as_is=. A boolean to suppress smart guess on dimensions.
; save_as_one=. A boolean to save value as a whole, i.e., nrec=1. Used to save metadata.
;-
pro cdf_save_var, varname, value=data, filename=cdf0, settings=settings, $
    compress=compress, cdf_type=cdf_type, $
    save_as_is=save_as_is, save_as_one=save_as_one

    compile_opt idl2
    catch, error
    if error ne 0 then begin
        catch, /cancel
        errmsg = handle_error(!error_state.msg, cdfid=cdfid)
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
            if file_test(path,/directory) eq 0 then file_mkdir, path
            cdfid = cdf_create(file)
        endif else cdfid = cdf_open(file)
    endif else cdfid = cdf0
    if keyword_set(compress) then cdf_compression, cdfid, set_gzip_level=compress



;---Save data. Needs to know cdf_type, numelem, dimensions
    vals = temporary(data)

    ; Delete existing var b/c dimension/rec/settings could be inconsistent.
    has_data = n_elements(vals)
    has_var = cdf_has_var(the_var, filename=cdfid)
    if has_var then cdf_del_var, the_var, filename=cdfid

    ; Get the cdf_type.
    var_type = keyword_set(cdf_type)? cdf_type: scdffmidltype(size(vals[0],/type))
    extra = create_struct(var_type,1)

    ; Get the data size.
    nrec = n_elements(vals)
    data_dims = size(vals,/dimensions)
    ndata_dim = n_elements(data_dims)

    ; Strings are special.
    numelem = 1
    if var_type eq 'CDF_CHAR' or var_type eq 'CDF_UCHAR' then begin
        for ii=0, nrec-1 do numelem >= strlen(vals[ii])
    endif

    ; Get the dimensions.
    ; Assume data in [nrec,dims], the convension used in tplot.
    if keyword_set(save_as_is) then begin
        dimensions = data_dims
    endif else if ndata_dim gt 1 then dimensions = data_dims[1:*]
    ; Scalar does not have dimension.
    if nrec eq 1 then dimensions = !null
    if ndata_dim eq 1 then dimensions = !null
    if n_elements(dimensions) ne 0 then begin
        ndimension = n_elements(dimensions)
        dimvary = bytarr(ndimension)+1
    endif
    ; CDF assumes [dims,nrec].
    if ~keyword_set(save_as_is) and n_elements(dimensions) ne 0 then vals = transpose(vals, shift(indgen(ndimension+1),-1))
    ; Sometimes we need to save all data as nrec=1.
    if keyword_set(save_as_one) then begin
        dimensions = data_dims
        dimvary = 1
        extra = create_struct('REC_NOVARY', 1, extra)
    endif

    ; Save data.
    if n_elements(dimensions) eq 0 then begin
        tmp = cdf_varcreate(cdfid, the_var, zvariable=1, numelem=numelem, _extra=extra)
    endif else begin
        tmp = cdf_varcreate(cdfid, the_var, dimvary, dimensions=dimensions, zvariable=1, numelem=numelem, _extra=extra)
    endelse
    cdf_varput, cdfid, the_var, vals, zvariable=1

    has_setting = isa(settings, 'dictionary')
    if has_setting then cdf_save_setting, settings, filename=cdfid, varname=the_var

    if input_is_file then cdf_close, cdfid


end
