;+
; Return a flag for if a given variable is in the file.
; var. A string for filename.
; filename=. A string for file or id.
;-

function netcdf_has_var, var, filename=input, errmsg=errmsg

    errmsg = ''
    retval = 0
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

    fileinq = ncdf_inquire(ncid)
    nvar = fileinq.nvars    ; # of variables defined in the file.
    for ii=0, nvar-1 do begin
        varinq = ncdf_varinq(ncid, ii)
        if varinq.name eq the_var then begin
            if input_is_file then ncdf_close, ncid
            return, 1
        endif
    endfor

    if input_is_file then ncdf_close, ncid
    return, 0

end

fn = '/Users/shengtian/Downloads/dn_magn-l2-hires_g13_d20130101_v0_0_2.nc'
print, netcdf_has_var('b_gsm', filename=fn)
print, netcdf_has_var('b_gsm2', filename=fn)
end
