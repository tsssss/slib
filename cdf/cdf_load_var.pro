;+
; Load one variable from one file, load all recs and depend_0.
; Save data to tplot.
;-
pro cdf_load_var, var, filename=cdf0, errmsg=errmsg

    errmsg = ''

    ; Check if var is a string.
    if n_elements(var) eq 0 then return
    the_var = var[0]

    ; Check if given file is a cdf_id or filename.
    if n_elements(cdf0) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return
    endif
    input_is_file = size(cdf0, /type) eq 7
    if input_is_file then begin
        file = cdf0
        if file_test(file) eq 0 then begin
            errmsg = handle_error('Input file does not exist ...')
            return
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
        return
    endif


;---Get vatts.
    vatt = dictionary()
    cdf_control, cdfid, get_numattrs=natt
    natt = total(natt)
    for ii=0, natt-1 do begin
        cdf_attinq, cdfid, ii, attname, scope, foo
        if strmid(scope,0,1) eq 'G' then continue
        if ~cdf_attexists(cdfid, attname, the_var) then continue
        cdf_attget, cdfid, attname, the_var, value
        vatt[attname] = value
    endfor

;---Load time_var if possible.
    no_time = 0
    keys = vatt.keys()
    nkey = n_elements(keys)
    if nkey eq 0 then begin
        message, 'No vatt ...', /continue
        no_time = 1
    endif
    index = where(strlowcase(keys) eq 'depend_0', count)
    if count eq 0 then begin
        message, 'No depend_0 ...', /continue
        no_time = 1
    endif
    if no_time then times = 0 else begin
        time_var = vatt[keys[index[0]]]
        times = cdf_read_var(time_var, filename=cdfid, errmsg=errmsg)
        if errmsg ne '' then times = 0
    endelse


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


;---Save to tplot.
    store_data, the_var, times, vals
    add_setting, the_var, /smart, vatt.tostruct()
    time_range = minmax(times)
    nsec = total(time_range*[-1,1])
    if nsec gt 0 then timespan, time_range[0], nsec, /seconds

end

var = 'the_bmod_t89'
fn = '/Volumes/GoogleDrive/My Drive/works/works/global_efield/data/cdf_data/the_bin_ready_data_v01.cdf'
cdf_load_var, var, filename=fn, errmsg=errmsg
end
