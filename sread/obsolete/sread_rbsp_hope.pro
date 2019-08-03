;+
; Type: <+++>.
; Purpose: <+++>.
; Parameters: <+++>.
;   <+varname+>, <+in/out+>, <+datatype+>, <+req/opt+>. <+++>.
; Keywords: <+++>.
;   <+varname+>, <+in/out+>, <+datatype+>, <+req/opt+>. <+++>.
; Return: <+++>.
; Notes: <+++>.
; Dependence: <+++>.
; History:
;   <+yyyy-mm-dd+>, Sheng Tian, create.
;-

function sread_rbsp_hope, tr0, probes = probe0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type, version = version
    
    compile_opt idl2
    
        
    ; **** prepare file names.
    if n_elements(type) eq 0 then type = 'level2'   ; can be level[2,3].
    prb = (n_elements(probe0))? probe0: 'a'
    vsn = (n_elements(version))? version: 'v[0-9.]{5}'
    ext = 'cdf'
    
    rempath = 'http://www.rbsp-ect.lanl.gov/data_pub/rbsp'+prb+'/hope/'+type
    locpath = sdiskdir('Research')+'/data/rbsp/rbsp'+prb+'/hope/'+type+'/YYYY/'
    baseptn = 'rbsp'+prb+'_rel03_ect-hope-sci-L'+strmid(type,strlen(type)-1)+'_YYYYMMDD_'+vsn+'.'+ext
        
    ; prepare locfns, nfn.
    sprepfile0, tr0, ptn = baseptn, locfns = locfns, remfns = remfns, $
        locroot = locpath, remroot = rempath
    nfn = n_elements(locfns)
    
    for i = 0, nfn-1 do begin
        tlocpath = file_dirname(locfns[i])
        trempath = file_dirname(remfns[i])
        locfns[i] = sgetfile(file_basename(locfns[i]), tlocpath, trempath)
    endfor
    idx = where(locfns ne '', nfn)
    if nfn ne 0 then locfns = locfns[idx] else return, -1
    
    
    ; **** prepare var names.
    if n_elements(var0s) eq 0 then $
        var0s = ['Epoch','Epoch_Ion','Epoch_Ion_DELTA',$
        'HOPE_ENERGY_Ion','Sector_Collapse_Cntr','Energy_Collapsed',$
        'L_Ion','MLT_Ion','FPDU','FODU','FHEDU']
    if n_elements(var1s) eq 0 then var1s = idl_validname(var0s)
    var1s = idl_validname(var1s)
    
    ; **** module for variable loading.
    nvar = n_elements(var0s)
    if nvar ne n_elements(var1s) then message, 'mismatch var names ...'
    ptrs = ptrarr(nvar)
    ; first file.
    tmp = scdfread(locfns[0],var0s)
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
    
    ; move data to structure.
    dat = create_struct(var1s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var1s[j],*ptrs[j])
    for j = 0, nvar-1 do ptr_free, ptrs[j]
    
;    c0 = 16384
;    vars = tag_names(dat)
;    tvar = ['FPDU','FODU','FHEDU','FEDU']
;    for i = 0, n_elements(tvar)-1 do begin
;        j = where(vars eq tvar[i], cnt)
;        if cnt eq 0 then continue
;        idx = where(dat.(j) gt c0, cnt)
;        if cnt eq 0 then continue
;        tmp = dat.(j)
;        tmp[idx] = (tmp[idx]-c0)*64+c0
;        dat.(j) = tmp
;    endfor

    vars = tag_names(dat)
    
    tmp = sdiskdir('Research')+'/data/rbsp/hope_coef.sav'
    if file_test(tmp) ne 0 then begin
        restore, filename = tmp
        j = where(vars eq 'FPDU', cnt)
        if cnt ne 0 then begin
            tmp = dat.(j)
            for i = 0, 71 do $
                for j = 0, 4 do tmp[*,i,*,j]*= coef_proton[i,j]
        endif
    endif
;    coefs = [1d,1,1,1.3407481,1.2221761]
;    tvar = ['FPDU','FODU','FHEDU','FEDU']
;    for i = 0, n_elements(tvar)-1 do begin
;        j = where(vars eq tvar[i], cnt)
;        if cnt eq 0 then continue
;        tmp = dat.(j)
;        for k = 0, 4 do tmp[*,*,*,k] *= coefs[k]
;        dat.(j) = tmp
;    endfor
    
    return, dat
        
end

utr = time_double(['2013-03-14/00:00','2013-03-14/00:10'])
hopel2 = sread_rbsp_hope(utr, probes = 'a', type = 'level2')
end