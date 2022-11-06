pro snetcdfskt, nc0, skeleton, filename=fn

    compile_opt idl2
    on_error, 0
    
    ; get netcdf id.
    if size(nc0,/type) eq 7 then begin
        if ~file_test(nc0) then message, 'file '+cdf0+' does not exist ...'
        ncid = ncdf_open(nc0)
    endif else ncid = nc0
    
    ; header info.
    fileinq = ncdf_inquire(ncid)
    ndim = fileinq.ndims    ; # of dimensions defined in the file.
    nvar = fileinq.nvars    ; # of variables defined in the file.
    ngatt = fileinq.ngatts  ; # of global attributes.
    recdim = fileinq.recdim ; ???.
    file = (size(nc0,/type) eq 7)? nc0: ''
    
    header = {$
        filename: file, $
        ngatt: ngatt, $
        nvar: nvar, $
        placeholder: 0b}
    
;---attribute.
    gatts = []
    for ii=0, ngatt-1 do begin
        attname0 = ncdf_attname(ncid, ii, /global)
        attinq = ncdf_attinq(ncid, attname0, /global)
        ncdf_attget, ncid, attname0, value, /global
        if size(value,/type) eq 1 then value = string(value)
        attname = idl_validname(attname0, /convert_all)
        gatts = create_struct(gatts, attname, {name:attname0, value:value})
    endfor
    

;---variable.
    vars = []
    for ii=0, nvar-1 do begin
        varinq = ncdf_varinq(ncid, ii)
        natt = varinq.natts     ; # of variable attribute.
        varname0 = varinq.name  ; original variable name.
        vatts = []
        for jj=0, natt-1 do begin
            attname0 = ncdf_attname(ncid, ii, jj)
            attinq = ncdf_attinq(ncid, ii, attname0)
            if attinq.datatype eq 'UNKNOWN' then begin
                value = !values.f_nan
            endif else begin
                ncdf_attget, ncid, ii, attname0, value
                if size(value,/type) eq 1 then value = string(value)
            endelse
            attname = idl_validname(attname0, /convert_all)
            vatts = create_struct(vatts, attname, {name:attname0, value:value})
        endfor
        
        varname = idl_validname(varname0, /convert_all)
        info = {$
            natt: natt, $
            atts: vatts, $
            name: varname0, $
            datatype: varinq.datatype, $
            dims: varinq.dim}
        vars = create_struct(vars, varname, info)
    endfor
    
    ; free id.
    if size(nc0,/type) eq 7 then ncdf_close, ncid
    
    
    ; return value.
    skeleton = {$
        name: header.filename, $
        header:header, $
        gatts: gatts, $
        vars: vars}
        
    ; output.
    if n_params() eq 1 then snetcdfsktlpr, skeleton, fn
    
end


fn = '/Users/Sheng/data/goes/new_full/2014/08/goes15/netcdf/g15_magneto_512ms_20140828_20140828.nc'
snetcdfskt, fn
end