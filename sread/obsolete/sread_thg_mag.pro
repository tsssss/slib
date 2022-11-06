;+
; Type: function.
; Purpose: Read Themis/asi MLT image for given site(s) for a time range.
;   Source: http://themis.ssl.berkeley.edu/data/themis.
; Parameter:
;   tr0, in, double/string, req. Set the time.
;       For double, it's the unix time or UTC. For string, it's the 
;       formatted string accepted by stoepoch, e.g., 'YYYY-MM-DD/hh:mm'.
;   site0, in, strarr[n], optional. The sites to be included. Include all sites
;       by default.
; Keywords:
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
; Return: struct. {epoch: epoch, mltimg: mltimg}.
; Notes: none.
; Dependence: slib.
; History:
;   2018-08-03, Sheng Tian, create.
;-
function sread_thg_mag, tr0, site0, exclude = exclude, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type0, version = version

    compile_opt idl2

    if n_elements(locroot) eq 0 then locroot = spreproot('themis')
    if n_elements(remroot) eq 0 then $
        remroot = 'http://themis.ssl.berkeley.edu/data/themis'

    type1 = 'mag'
    type2 = 'mag'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'

    baseptns = ['thg_l2_'+type1+'_'+site0,'_YYYYMMDD_',vsn+'.'+ext]
    nbaseptn = n_elements(baseptns)
    ptnflags = [0,1,0]
    rempaths = [remroot+'/thg/l2/'+type1+'/'+site0,'YYYY',baseptns]
    locpaths = [locroot+'/thg/l2/'+type1+'/'+site0,'YYYY',baseptns]
    ptnflags = [0,1,ptnflags]

    remfns = sprepfile(tr0, paths=rempaths, flags=ptnflags, nbase=nbaseptn)
    locfns = sprepfile(tr0, paths=locpaths, flags=ptnflags, nbase=nbaseptn)
    nfn = n_elements(locfns)
    for i = 0, nfn-1 do begin
        basefn = file_basename(locfns[i])
        locpath = file_dirname(locfns[i])
        rempath = file_dirname(remfns[i])
        locfns[i] = sgetfile(basefn, locpath, rempath)
    endfor
    idx = where(locfns ne '', nfn)    
    if nfn ne 0 then locfns = locfns[idx] else return, -1


;---prepare var names.
    if n_elements(var0s) eq 0 then begin
        var0s = 'thg_mag_'+site0+['','_time']
    endif
    if n_elements(var1s) eq 0 then var1s = idl_validname(var0s)
    var1s = idl_validname(var1s)
    
;---module for variable loading.
    nvar = n_elements(var0s)
    if nvar ne n_elements(var1s) then message, 'mismatch var names ...'
    ptrs = ptrarr(nvar)
    ; first file.
    tmp = scdfread(locfns[0],var0s, skt=skt)
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

;---finish.
    return, dat

end

mag = sread_thg_mag(time_double(['2014-08-28','2014-08-29']), 'mcgr')
end
