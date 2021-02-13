;+
; Return a dict of attribute of given variable.
;
; var. A string for var name.
; filename. A string for file name or a id.
;-

function netcdf_read_var_att, var, filename=input, errmsg=errmsg

    errmsg = ''
    retval = hash()

    ; Check if var is a string.
    if n_elements(var) eq 0 then return, retval
    the_var = var[0]


    ; Check if given file is a cdf_id or filename.
    if n_elements(input) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return, retval
    endif
    input_is_file = size(input,/type) eq 7
    if input_is_file then begin
        file = input
        if file_test(file) eq 0 then begin
            errmsg = handle_error('Input file does not exist ...')
            return, retval
        endif
        ncid = ncdf_open(file)
    endif else begin
        ncid = input
    endelse

    ; No var is found.
    if ~netcdf_has_var(the_var,filename=ncid) then begin
        errmsg = handle_error('File does not have var: '+the_var+' ...')
        if input_is_file then ncdf_close, ncid
        return, retval
    endif

    varid = ncdf_varid(ncid, the_var)
    varinq = ncdf_varinq(ncid, varid)
    natt = varinq.natts     ; # of variable attribute.
    for jj=0, natt-1 do begin
        attname = ncdf_attname(ncid, varid, jj)
        attinq = ncdf_attinq(ncid, varid, attname)
        if attinq.datatype eq 'UNKNOWN' then begin
            value = !null
        endif else begin
            ncdf_attget, ncid, varid, attname, value
            if attinq.datatype eq 'CHAR' then value = string(value)
        endelse
        retval[attname] = value
    endfor

    if input_is_file then ncdf_close, ncid
    return, retval

end

fn = '/Users/shengtian/Downloads/dn_magn-l2-hires_g13_d20130101_v0_0_2.nc'
var = 'b_gsm'
vatt =  netcdf_read_setting(var, filename=fn)
end