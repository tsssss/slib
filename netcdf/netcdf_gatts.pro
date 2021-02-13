;+
; Return all global attributes in the netCDF file.
;-

function netcdf_gatts, input, errmsg=errmsg

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

    fileinq = ncdf_inquire(ncid)
    ngatt = fileinq.ngatts  ; # of global attributes.
    nvar = fileinq.nvars    ; # of variables defined in the file.
    attnames = list()
    for ii=0, ngatt-1 do begin
        attnames.add, ncdf_attname(ncid, ii, /global)
    endfor

    if input_is_file then ncdf_close, ncid
    if n_elements(attnames) eq 0 then return, retval
    return, attnames.toarray()

end


fn = '/Users/shengtian/Downloads/dn_magn-l2-hires_g13_d20130101_v0_0_2.nc'
help, netcdf_gatts(fn)
help, netcdf_atts(fn)
end
