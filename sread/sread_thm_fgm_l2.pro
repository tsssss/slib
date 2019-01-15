;+
; Type: function.
; Purpose: Read THEMIS B field data.
;   Source: ftp://cdaweb.gsfc.nasa.gov/pub/data/themis
; Parameters:
;   tr0, in, double/string or dblarr[2]/strarr[2], req. If in double or
;       string, set the time; if in dblarr[2] or strarr[2], set the time range.
;       For double or dblarr[2], it's the unix time or UTC. For string or
;       strarr[2], it's the formatted string accepted by stoepoch, e.g.,
;       'YYYY-MM-DD/hh:mm'.
; Keywords:
;   probes, in, string or strarr[2], opt. 'a' to 'e'. Default is 'a'.
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   type, in, string, optional.
;   version, in, string, optional. Data version. In case to load an old
;       version data. By default, the highest version is loaded.
;   vars, in, strarr[n], optional. The vars to be loaded.
;   newnames, in, strarr[n], optional. The new names for the vars.
; Return: struct.
; Notes: none.
; History:
;   2018-02-20, Sheng Tian, create.
;-

function sread_thm_fgm_l2, tr0, probes = probe0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type0, version = version

    compile_opt idl2

;---local and remote directory.
    sep = path_sep()
    if n_elements(locroot) eq 0 then locroot = spreproot('themis')
    if n_elements(remroot) eq 0 then $
        remroot = 'ftp://cdaweb.gsfc.nasa.gov/pub/data/themis'
    
;---prepare file names.
    type1 = 'fgm'   ; use in filename.
    type2 = 'fgm'   ; use in path.
    prb = (n_elements(probe0))? probe0: 'a'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'

    baseptns = ['th'+prb+'_l2_'+type1,'_YYYYMMDD_',vsn+'.'+ext]
    nbaseptn = n_elements(baseptns)
    ptnflags = [0,1,0]
    rempaths = [remroot+'/th'+prb+'/l2/'+type1,'YYYY',baseptns]
    locpaths = [locroot+'/th'+prb+'/l2/'+type1,'YYYY',baseptns]
    ptnflags = [0,1,ptnflags]

    remfns = sprepfile(tr0, paths = rempaths, flags=ptnflags, nbase=nbaseptn)
    locfns = sprepfile(tr0, paths = locpaths, flags=ptnflags, nbase=nbaseptn)
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
    pre0 = 'th'+prb+'_'
    if n_elements(var0s) eq 0 then begin
        var0s = pre0+['fgs_time','fgs_gsm']    ; 3 sec resolution.
        ;var0s = pre0+['fgl_time','fgl_gsm']    ; 0.008 sec resolution.
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
