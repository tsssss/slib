;+
; Read or print the skeleton of a cdf file.
;-
function cdf_read_skeleton, cdf0

    retval = dictionary()
    ; Check if given file is a cdf_id or filename.
    if n_elements(cdf0) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return, retval
    endif
    input_is_file = size(cdf0, /type) eq 7
    if input_is_file then begin
        file = cdf0
        path = fgetpath(file)
        if file_test(file) eq 0 then begin
            if file_test(path,/directory) eq 0 then file_mkdir, path
            cdfid = cdf_create(file)
        endif else cdfid = cdf_open(file)
    endif else cdfid = cdf0


;---Header info.
    skeleton = dictionary()
    cdfinq = cdf_inquire(cdfid)
    cdf_doc, cdfid, vsn, rls, cpy, increment = inc
    vsn = string(vsn, rls, inc, format = '(I0,".",I0,".",I0)')
    cdf_control, cdfid, get_filename = fn0, $
        get_format = fmt, get_numattrs = natts
    ngatt = natts[0]
    nvatt = natts[1]
    nrvar = cdfinq.nvars
    nzvar = cdfinq.nzvars

    header = dictionary($
        'copyright', cpy, $
        'cdfformat', fmt, $
        'decoding', cdfinq.decoding, $
        'encoding', cdfinq.encoding, $
        'filename', fn0+'.cdf', $
        'majority', cdfinq.majority, $
        'version', vsn, $
        'ngatt', ngatt, $
        'nvatt', nvatt, $
        'nzvar', nzvar, $
        'nrvar', nrvar )
    skeleton['header'] = header
    skeleton['name'] = header.filename

;---Global attributes.
    skeleton['setting'] = cdf_read_setting(filename=cdfid)

;---Variables.
    vars = hash()
    for ii=0, nrvar-1 do begin
        ; variable info.
        varinq = cdf_varinq(cdfid, ii)
        cdf_control, cdfid, variable=ii, get_var_info=varinfo
        recvary = varinq.recvar eq 'VARY'
        info = dictionary($
            'name', varinq.name, $
            'cdftype', varinq.datatype, $
            'nelem', varinq.numelem, $
            'iszvar', 0, $
            'recvary', recvary, $
            'maxrec', varinfo.maxrec+1, $
            'dims', cdfinq.dim, $
            'dimvary', varinq.dimvar )
        vars[varinq.name] = info
    endfor

    for ii=0, nzvar-1 do begin
        ; varialbe info.
        varinq = cdf_varinq(cdfid, ii, zvariable=1)
        cdf_control, cdfid, variable=ii, get_var_info=varinfo, zvariable=1
        recvary = varinq.recvar eq 'VARY'
        info = dictionary($
            'name', varinq.name, $
            'cdftype', varinq.datatype, $
            'nelem', varinq.numelem, $
            'iszvar', 1, $
            'recvary', recvary, $
            'maxrec', varinfo.maxrec+1, $
            'dims', varinq.dim, $
            'dimvary', varinq.dimvar )
        vars[varinq.name] = info
    endfor

;---Variable attribute.
    foreach var, vars.keys() do (vars[var])['setting'] = cdf_read_setting(var, filename=cdf0)
    skeleton['var'] = vars


;---Wrap up.
    if input_is_file then cdf_close, cdfid
    return, skeleton

end
