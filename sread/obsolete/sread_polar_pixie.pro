
function sread_polar_pixie, tr0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type, version = version
    
    compile_opt idl2

    ; local and remote directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('polar/pixie')
    if n_elements(remroot) eq 0 then $
        remroot = 'http://pixie.spasci.com/Data/l1_cdf/l1_cdf_1996_2002'
        
    
    ; **** prepare file names.
    type = 'c1'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'
    
    baseptn = 'po_'+type+'_pix_yyyyMMdd_'+vsn+'.'+ext
    rempaths = [remroot,'YYYY','YYYYMM',baseptn]
    locpaths = [locroot,'YYYY',baseptn]
    remfns = sprepfile(tr0, paths = rempaths)
    locfns = sprepfile(tr0, paths = locpaths)
    
    nfn = n_elements(locfns)
    locidx = 'SHA1SUM'
    for i = 0, nfn-1 do begin
        basefn = file_basename(locfns[i])
        locpath = file_dirname(locfns[i])
        rempath = file_dirname(remfns[i])
        locfns[i] = sgetfile(basefn, locpath, rempath, locidx = locidx)
    endfor
    
    idx = where(locfns ne '', nfn)
    if nfn ne 0 then locfns = locfns[idx] else return, -1
    
    
    ; **** prepare var names.
    epvname = 'Epoch'
    if n_elements(var0s) eq 0 then $
        var0s = [epvname,'Nz_Nf']
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
    
    ; move data to structure.
    dat = create_struct(var1s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var1s[j],*ptrs[j])
    for j = 0, nvar-1 do ptr_free, ptrs[j]
    
    return, dat
        
end

utr = time_string(['2001-10-21','2001-10-24'])
tmp = sread_polar_pixie(utr)
uts = sfmepoch(tmp.epoch,'unix')
dat = double(tmp.(1)); & dat[where(dat eq max(dat))] = !values.d_nan
store_data, 'po_pixie', uts, dat

; load ae.
omni = sread_omni(utr, vars = ['Epoch','AE_INDEX'])
store_data, 'ae', sfmepoch(omni.epoch, 'unix'), omni.ae_index, $
    limits = {ytitle:'AE (nT)', constant:500, yrange:[0,1500]}
    
tplot, ['ae','po_pixie'], trange = utr
end