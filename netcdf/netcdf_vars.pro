;+
; Return all variables in the netCDF file.
;-

function netcdf_vars, input, errmsg=errmsg

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

    ; Loop through variables in the file.
    varnames = list()
    fileinq = ncdf_inquire(ncid)
    nvar = fileinq.nvars    ; # of variables defined in the file.
    for ii=0, nvar-1 do begin
        varinq = ncdf_varinq(ncid, ii)
        varnames.add, varinq.name
    endfor

    if input_is_file then ncdf_close, ncid
    if n_elements(varnames) eq 0 then return, retval
    return, varnames.toarray()

end


fn = '/Users/shengtian/Downloads/dn_magn-l2-hires_g13_d20130101_v0_0_2.nc'
print, netcdf_vars(fn)
end
