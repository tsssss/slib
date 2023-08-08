;+
; Return all variable attributes in the netCDF file.
;-

function netcdf_vatts, input, errmsg=errmsg

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
    nvar = fileinq.nvars    ; # of variables defined in the file.
    attnames = list()
    for ii=0, nvar-1 do begin
        varinq = ncdf_varinq(ncid, ii)
        natt = varinq.natts     ; # of variable attribute.
        for jj=0, natt-1 do begin
            attname0 = ncdf_attname(ncid, ii, jj)
            if attnames.where(attname0) ne !null then continue
            attnames.add, attname0
        endfor
    endfor

    if input_is_file then ncdf_close, ncid
    if n_elements(attnames) eq 0 then return, retval
    return, attnames.toarray()

end


fn = '/Users/shengtian/Downloads/dn_magn-l2-hires_g13_d20130101_v0_0_2.nc'
help, netcdf_atts(fn)
help, netcdf_gatts(fn)
help, netcdf_vatts(fn)
end
