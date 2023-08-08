;+
; Read skeleton of a netcdf file.
; To replace snetcdfskt.pro.
;-
function netcdf_read_skeleton, nc0

    retval = dictionary()
    ; Check if given file is a cdf_id or filename.
    if n_elements(nc0) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return, retval
    endif
    input_is_file = size(nc0, /type) eq 7
    if input_is_file then begin
        file = nc0
        path = fgetpath(file)
        if file_test(file) eq 0 then begin
            if file_test(path,/directory) eq 0 then file_mkdir, path
            ncid = ncdf_create(file)
        endif else ncid = ncdf_open(file)
    endif else ncid = nc0


;---Header info.
    skeleton = dictionary()
    fileinq = ncdf_inquire(ncid)
    ndim = fileinq.ndims    ; # of dimensions defined in the file.
    nvar = fileinq.nvars    ; # of variables defined in the file.
    ngatt = fileinq.ngatts  ; # of global attributes.
    recdim = fileinq.recdim ; ???.
    file = (size(nc0,/type) eq 7)? nc0: ''
    
    header = dictionary($
        'filename', file, $
        'ngatt', ngatt, $
        'nvar', nvar )
    skeleton['header'] = header
    skeleton['name'] = header.filename


;---Global attributes.
    skeleton['setting'] = netcdf_read_setting(filename=ncid)


;---Variables.
    vars = orderedhash()
    for ii=0,nvar-1 do begin
        varinq = ncdf_varinq(ncid, ii)
        info = dictionary($
            'name', varinq.name, $
            'datatype', varinq.datatype, $
            'dims', varinq.dim )
        vars[varinq.name] = info
    endfor

;---Variable attribute.
    foreach var, vars.keys() do (vars[var])['setting'] = netcdf_read_setting(var, filename=ncid)
    skeleton['var'] = vars


;---Wrap up.
    if input_is_file then ncdf_close, ncid
    return, skeleton

end