;+
; Read and return one variable from one file.
;-
function cdf_read_var, var, filename=cdf0, errmsg=errmsg

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

    ; Loop through variables in the file.
    cdfinq = cdf_inquire(cdfid)
    nzvar = cdfinq.nzvars
    vinfo = dictionary()
    for ii=0, nzvar-1 do begin
        varinq = cdf_varinq(cdfid, ii, zvariable=1)
        if varinq.name eq the_var then begin
            vinfo['name'] = the_var
            vinfo['iszvar'] = 1
            vinfo['dims'] = varinq.dim
            vinfo['dimvary'] = varinq.dimvar
            vinfo['recvary'] = varinq.recvar eq 'VARY'
            break
        endif
    endfor

    nrvar = cdfinq.nvars
    for ii=0, nrvar-1 do begin
        varinq = cdf_varinq(cdfid, ii, zvariable=0)
        if varinq.name eq the_var then begin
            vinfo['name'] = the_var
            vinfo['iszvar'] = 0
            vinfo['dims'] = varinq.dim
            vinfo['dimvary'] = varinq.dimvar
            vinfo['recvary'] = varinq.recvar eq 'VARY'
            break
        endif
    endfor

    if ~vinfo.haskey('name') then begin
        errmsg = handle_error(cdfid=cdfid, 'File does not has var: '+the_var+' ...')
        return, retval
    endif


;---Load the_var.
    cdf_control, cdfid, variable=vinfo.name, get_var_info=varinfo
    nrec = varinfo.maxrec+1

    shrink = total(vinfo.dimvary eq 0) gt 0
    if vinfo.dims[0] eq 0 then shrink = 0  ; scalar element.
    ; read variable.
    if shrink then begin
        cdf_varget, cdfid, vinfo.name, tval, /string, rec_start = 0
        tmp = [nrec,vinfo.dims]
        vals = make_array(type=size(tval,/type), tmp[where([1,vinfo.dimvary] eq 1)])
        for jj = 0, nrec-1 do begin
            cdf_varget, cdfid, vinfo.name, tval, /string, rec_start=jj
            vals[j,*,*,*,*,*,*,*] = srmdim(tval, vinfo.dimvary)
        endfor
    endif else begin
        cdf_varget, cdfid, vinfo.name, vals, /string, rec_start=0, rec_count=nrec
        ; vals = reform(vals), reform causes problem when concatenate data.
        ; permute dimensions.
        if nrec ne 1 and size(vals,/n_dimensions) gt 1 then $
            vals = transpose(vals,shift(indgen(n_elements(vinfo.dims)+1),1))
    endelse
    if input_is_file then cdf_close, cdfid

    return, vals


end

var = 'the_bmod_t89'
fn = '/Volumes/GoogleDrive/My Drive/works/works/global_efield/data/cdf_data/the_bin_ready_data_v01.cdf'
data = cdf_read_var(var, filename=fn, errmsg=errmsg)
end
