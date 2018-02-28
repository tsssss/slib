;+
; Sett variable type in extra!!.
;-
pro scdfwrite, cdf0, vname, recs, skt = skt, value = val, $
    cdftype = cdftype, dimvary=dimvary, $
    attributes = vattinfo, reset = reset, gattributes = gattinfo, $
    _extra = extra

    compile_opt idl2
    on_error, 0
    quiet0 = !quiet
    !quiet = 1

    ; get cdf id.
    if size(cdf0, /type) eq 7 then begin
        if ~file_test(cdf0) then begin  ; creat the file.
            message, 'file ' + cdf0 + ' does not exist ...', /continue
            cdfid = cdf_create(cdf0)
            newfile = 1
        endif else newfile = 0
        if newfile eq 0 then cdfid = cdf_open(cdf0)
    endif else cdfid = cdf0


    ; read skeleton.
    if n_elements(skt) eq 0 then scdfskt, cdfid, skt
    
    ; global attributions.
    ngatt = skt.header.ngatt
    if ngatt gt 0 then gatts = tag_names(skt.att)
    if n_elements(gattinfo) ne 0 then begin
        gattnames = tag_names(gattinfo)
        ngattname = n_elements(gattnames)
        for i = 0, ngattname-1 do begin
            if ngatt eq 0 then newatt = 1 else begin
                idx = where(gatts eq gattnames[i], cnt)
                if cnt eq 0 then newatt = 1 else newatt = 0
            endelse
            if newatt eq 1 then $
                attid = cdf_attcreate(cdfid, gattnames[i], /global_scope)
            gentry = newatt? attid: idx
            cdf_attput, cdfid, gattnames[i], gentry, gattinfo.(i)
        endfor
    endif
    
    if n_elements(vname) eq 0 then begin
        cdf_close, cdfid
        return
    endif

    ; original variable names.
    novar = skt.header.nrvar+skt.header.nzvar
    if novar eq 0 then newvar = 1 else begin
        ovnames = strarr(novar)
        for i = 0, novar-1 do ovnames[i] = skt.var.(i).name
        idx = where(ovnames eq vname, cnt)
        if cnt eq 0 then newvar = 1 else newvar = 0
    endelse
    
    if newvar eq 0 and keyword_set(reset) then begin
        newvar = 1
        for i = 0, novar-1 do if skt.var.(i).name eq vname then break
        vattinfo0 = skt.var.(i).att
        cdf_vardelete, cdfid, vname, zvariable = skt.var.(i).iszvar
    endif
    
    if newvar eq 1 then begin
        ; deal with cdf_type.
        vtype = keyword_set(cdftype)? cdftype: scdffmidltype(size(val[0],/type))
        if n_elements(extra) eq 0 then extra1 = create_struct(vtype,1) else begin
            idx = where(tag_names(extra) eq strupcase(vtype), cnt)
            if cnt eq 0 then extra1 = create_struct(vtype,1, extra) else begin
                extra1 = extra & extra1.(idx) = 1
            endelse
        endelse
        if n_elements(dimvary) eq 0 then begin
            varid = cdf_varcreate(cdfid, vname, _extra = extra1, /zvariable)
        endif else begin
            varid = cdf_varcreate(cdfid, vname, dimvary, _extra = extra1, /zvariable)
        endelse
    endif

    cdf_varput, cdfid, vname, val
    
    ; variable attributions.
    nvatt = skt.header.nvatt
    if nvatt gt 0 then vatts = skt.vatt
    if n_elements(vattinfo) ne 0 then begin
        vattnames = tag_names(vattinfo)
        nvattname = n_elements(vattnames)
        for i = 0, nvattname-1 do begin
            if nvatt eq 0 then newatt = 1 else begin
                idx = where(vatts eq vattnames[i], cnt)
                if cnt eq 0 then newatt = 1 else newatt = 0
            endelse
            if newatt eq 1 then $
                attid = cdf_attcreate(cdfid, vattnames[i], /variable_scope)
            cdf_attput, cdfid, vattnames[i], vname, vattinfo.(i)
        endfor
    endif
        
    cdf_close, cdfid

end

fn = shomedir()+'/test.cdf'
vname = 'angle'
val = 1
scdfwrite, fn, vname, value = val
cdf = scdfread(fn, vname)
print, *cdf[0].value

val = [2,3,4]
scdfwrite, fn, vname, value = val
cdf = scdfread(fn, vname)
print, *cdf[0].value

file_delete, fn
end