;+
; type can be esvy, vsvy, euvw. esvy is the default type.
;-

function sread_rbsp_efw_l2, tr0, probes = probe0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type0, version = version
    
    compile_opt idl2
    
    ; local and remote directory.
    sep = path_sep()
    if n_elements(locroot) eq 0 then locroot = spreproot('rbsp')
    if n_elements(remroot) eq 0 then $
        remroot = 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
;        remroot = 'http://rbsp.space.umn.edu/data/rbsp'
;        remroot = 'ftp://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
    
    ; **** prepare file names.
    type = (n_elements(type0))? type0: 'esvy'
    prb = (n_elements(probe0))? probe0: 'a'
    vsn = (n_elements(version))? version: 'v[0-9.]{2}'
    ext = 'cdf'
    
    ; type1 in filename, type2 in path.
    case type of
        'vsvy': begin
            type1 = 'vsvy-hires'
            type2 = 'vsvy-highres' & end
        'esvy': begin
            type1 = 'esvy_despun'
            type2 = 'esvy_despun' & end
        'euvw': begin
            type1 = 'e-hires-uvw'
            type2 = 'e-highres-uvw' & end
        else:   ; do nothing.
    endcase
    
    baseptn = 'rbsp'+prb+'_efw-l2_'+type1+'_YYYYMMDD_'+vsn+'.'+ext
    rempaths = [remroot,'rbsp'+prb,'l2','efw',type2,'YYYY',baseptn]
    locpaths = [locroot,'rbsp'+prb,'efw/l2',type2,'YYYY',baseptn]

    if remroot eq 'http://rbsp.space.umn.edu/data/rbsp' then $
        rempaths = [remroot,'rbsp'+prb,'l2',type1,'YYYY',baseptn] ; for umn server.

    
    remfns = sprepfile(tr0, paths = rempaths)
    locfns = sprepfile(tr0, paths = locpaths)
    nfn = n_elements(locfns)
    for i = 0, nfn-1 do begin
        basefn = file_basename(locfns[i])
        locpath = file_dirname(locfns[i])
        rempath = file_dirname(remfns[i])
        locfns[i] = sgetfile(basefn, locpath, rempath)
    endfor
    idx = where(locfns ne '', nfn)
    if nfn ne 0 then locfns = locfns[idx] else return, -1
    
    
    ; **** prepare var names.
    if n_elements(var0s) eq 0 then begin
        scdfskt, locfns[0], skt
        case type of
            'esvy': begin
                tvar = 'efield_mgse'
                idx = where(tag_names(skt.var) eq strupcase(tvar),cnt)
                if cnt eq 0 then evar = '' else $
                    evar = skt.var.(idx).att.depend_0.value                
                var0s = [evar, tvar]
                var1s = ['epoch','efield_mgse'] & end
            'vsvy': begin
                tvar = 'vsvy'
                idx = where(tag_names(skt.var) eq strupcase(tvar),cnt)
                evar = skt.var.(idx).att.depend_0.value
                var0s = [evar,tvar]
                var1s = ['epoch','vsvy'] & end
            'euvw': begin
                tvar = skt.var.(1).name ; can be 'efield_uvw' or 'e_hires_uvw'.
                evar = skt.var.(where( $
                    tag_names(skt.var) eq strupcase(tvar))).att.depend_0.value
                var0s = [evar, tvar]  
                var1s = ['epoch','efield_uvw'] & end
            else: message, 'have not treat type '+type+' yet ...'
        endcase
    endif
    if n_elements(var1s) eq 0 then var1s = idl_validname(var0s)
    var1s = idl_validname(var1s)
    
    
    ; **** module for variable loading.
    nvar = n_elements(var0s)
    if nvar ne n_elements(var1s) then message, 'mismatch var names ...'
    ptrs = ptrarr(nvar)
    ; first file.
    tmp = scdfread(locfns[0],var0s)
    if n_elements(tmp) lt n_elements(var0s) then return, -1
    for j = 0, nvar-1 do ptrs[j] = (tmp[j].value)
    ; rest files.
    for i = 1, nfn-1 do begin
        tmp = scdfread(locfns[i],var0s)
        for j = 0, nvar-1 do begin
            ; works for all dims b/c cdf records on the 1st dim of array.
            *ptrs[j] = [*ptrs[j],*(tmp[j].value)]
            ptr_free, tmp[j].value  ; release pointers.
        endfor
    endfor
    
    ; trim to time, change time to normal epoch.
    epvar = 'epoch'
    if size(tr0,/type) eq 7 then tformat = '' else tformat = 'unix'
    eps = stoepoch(tr0,tformat)
    idx = (where(var1s eq epvar, cnt))[0]
    if cnt ne 0 then begin
        tmp = stoepoch(*(ptrs[idx]), 'epoch16')
        *(ptrs[idx]) = tmp
        idx = where(tmp ge min(eps) and tmp le max(eps))
        for i = 0, nvar-1 do *ptrs[i] = (*ptrs[i])[idx,*,*,*,*,*,*,*]        
    endif
    
    ; fill value.
    fillval = -1e31
    for j = 0, nvar-1 do begin
        idx = where((*ptrs[j]) eq fillval, cnt)
        if cnt eq 0 then continue
        (*ptrs[j])[idx] = !values.d_nan
    endfor
    
    ; move data to structure.
    dat = create_struct(var1s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var1s[j],*ptrs[j])
    for j = 0, nvar-1 do ptr_free, ptrs[j]
    
    return, dat
    
end

utr = time_string(['2012-11-21'])
efwl2 = sread_rbsp_efw_l2(utr, probes = 'a')
uts = sfmepoch(efwl2.epoch,'unix',/epoch16)
store_data, 'dey_despun', uts, efwl2.efield_mgse[*,1]

end

