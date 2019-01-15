;+
; Type: function.
; Purpose: read RBSP EFW L1 data.
; Parameters: <+++>.
;   <+varname+>, <+in/out+>, <+datatype+>, <+req/opt+>. <+++>.
; Keywords: <+++>.
;   <+varname+>, <+in/out+>, <+datatype+>, <+req/opt+>. <+++>.
; Return: <+++>.
; Notes: <+++>.
; Dependence: <+++>.
; History:
;   2016-06-10, Sheng Tian, create.
;-

function sread_rbsp_efw_l1, tr0, probes = probe0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type, version = version

    compile_opt idl2
    
    ; local and remote directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('rbsp')
    if n_elements(remroot) eq 0 then $
        remroot = 'http://themis.ssl.berkeley.edu/data/rbsp'

    ; **** prepare file names.
    type = (n_elements(type))? type: 'esvy'
    prb = (n_elements(probe0))? probe0: 'a'
    vsn = (n_elements(version))? version: 'v[0-9.]{2}'
    ext = 'cdf'
    
    baseptn = 'rbsp'+prb+'_l1_'+type+'_YYYYMMDD_'+vsn+'.'+ext
    rempaths = [remroot,'rbsp'+prb,'l1',type,'YYYY',baseptn]
    locpaths = [locroot,'rbsp'+prb,'efw/l1',type,'YYYY',baseptn]

    ; prepare locfns, nfn.
    remfns = sprepfile(tr0, paths = rempaths)
    locfns = sprepfile(tr0, paths = locpaths)
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
        var0s = ['epoch','esvy']
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

    fillval = -1e31
    for j = 0, nvar-1 do begin
        idx = where(dat.(j) eq fillval, cnt)
        if cnt eq 0 then continue
        tmp = dat.(j)
        tmp[idx] = !values.d_nan
        dat.(j) = tmp
    endfor

    return, dat

end

utr = time_string(['2013-05-19'])
efwl3 = sread_rbsp_efw_l1(utr)

end
