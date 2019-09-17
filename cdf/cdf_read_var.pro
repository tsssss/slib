;+
; Read and return one variable from one file.
; range=. A record range, e.g., [0,100].
;-
function cdf_read_var, var, range=range, filename=cdf0, errmsg=errmsg

    errmsg = ''
    retval = !null

    ; Check if var is a string.
    if n_elements(var) eq 0 then return, retval
    the_var = var[0]

    ; Check if given file is a cdf_id or filename.
    if n_elements(cdf0) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return, retval
    endif
    input_is_file = size(cdf0, /type) eq 7
    if input_is_file then begin
        file = cdf0
        if file_test(file) eq 0 then begin
            errmsg = handle_error('Input file does not exist ...')
            return, retval
        endif
        cdfid = cdf_open(file)
    endif else begin
        cdfid = cdf0
    endelse

    ; Check if given var is in the file.
    if ~cdf_has_var(the_var, filename=cdfid, iszvar=iszvar) then begin
        errmsg = handle_error(cdfid=cdfid, 'File does not has var: '+the_var+' ...')
        return, retval
    endif


;---Load the_var.
    cdf_control, cdfid, variable=the_var, get_var_info=varinfo
    varinq = cdf_varinq(cdfid, the_var, zvariable=iszvar)
    nrec = varinfo.maxrec
    if nrec le 0 then begin
        errmsg = handle_error(cdfid=cdfid, 'No record ...')
        return, retval
    endif
    if n_elements(range) ne 2 then range = [0,nrec]
    rec_min = min(range)
    nrec = max(range)-rec_min+1

    shrink = total(varinq.dimvar eq 0) gt 0
    if varinq.dim[0] eq 0 then shrink = 0  ; scalar element.
    ; read variable.
    if shrink then begin
        cdf_varget, cdfid, the_var, tval, /string, rec_start=rec_min
        tmp = [nrec,varinq.dim]
        vals = make_array(type=size(tval,/type), tmp[where([1,varinq.dimvar] eq 1)])
        for jj=rec_min, nrec-1 do begin
            cdf_varget, cdfid, the_var, tval, /string, rec_start=jj
            vals[j,*,*,*,*,*,*,*] = srmdim(tval, varinq.dimvar)
        endfor
    endif else begin
        cdf_varget, cdfid, the_var, vals, /string, rec_start=rec_min, rec_count=nrec
        ; vals = reform(vals), reform causes problem when concatenate data.
        ; permute dimensions.
        if nrec ne 1 and size(vals,/n_dimensions) gt 1 then $
            vals = transpose(vals,shift(indgen(n_elements(varinq.dim)+1),1))
    endelse
    
    if input_is_file then cdf_close, cdfid
    return, vals


end

var = 'tha_efs_dot0_time'
fn = '/Users/shengtian/Downloads/tha_l2_efi_20110101_v01.cdf'
data = cdf_read_var(var, filename=fn, errmsg=errmsg)
end
