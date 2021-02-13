;+
; Read and return one variable from one file.
; 
; var. A string for the variable.
; filename=. 
; range=. A record range, e.g, [0,100]. Dummy keyword.
;-

function netcdf_read_var, var, range=range, filename=input, errmsg=errmsg

    errmsg = ''
    retval = !null

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


    the_var = var[0]
    if ~netcdf_has_var(the_var, filename=ncid) then begin
        errmsg = handle_error('File does not has var: '+the_var+' ...')
        if input_is_file then ncdf_close, ncid
        return, retval
    endif


;---Load the_var.
    varid = ncdf_varid(ncid, the_var)
    varinq = ncdf_varinq(ncid, varid)
    if varinq.datatype eq 'UNKNOWN' then begin
        if input_is_file then ncdf_close, ncid
        errmsg = handle_error('Variable data type is unknown ...')
        return, retval
    endif
    ncdf_varget, ncid, varid, value

    if input_is_file then ncdf_close, ncid
    return, value

end

fn = '/Users/shengtian/Downloads/dn_magn-l2-hires_g13_d20130101_v0_0_2.nc'

var = 'b_gsm'
data = netcdf_read_var(var, filename=fn)
help, data
stop

range = [0,5]
data2 = netcdf_read_var(var, filename=fn, range=range)
help, data2

var = 'method'
data = netcdf_read_var(var, filename=fn)
help, data

end
