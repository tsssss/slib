;+
; Return a dictionary of settings.
;-

function netcdf_read_setting, var, filename=input, errmsg=errmsg

    errmsg = ''
    retval = hash()

    ; Check if return vatt or gatt.
    vatt_mode = n_elements(var) gt 0
    if vatt_mode then return, netcdf_read_var_att(var, filename=input, errmsg=errmsg)

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

    fileinq = ncdf_inquire(ncid)
    ngatt = fileinq.ngatts  ; # of global attributes.
    for ii=0, ngatt-1 do begin
        attname = ncdf_attname(ncid, ii, /global)
        attinq = ncdf_attinq(ncid, attname, /global)
        if attinq.datatype eq 'UNKNOWN' then begin
            value = !null
        endif else begin
            ncdf_attget, ncid, attname, value, /global
            if attinq.datatype eq 'CHAR' then value = string(value)
        endelse
        retval[attname] = value
    endfor

    if input_is_file then ncdf_close, ncid
    return, retval

end


fn = '/Users/shengtian/Downloads/dn_magn-l2-hires_g13_d20130101_v0_0_2.nc'
gatt =  netcdf_read_setting(filename=fn)

var = 'b_gsm'
vatt =  netcdf_read_setting(var, filename=fn)
end
