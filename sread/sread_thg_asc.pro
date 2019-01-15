;+
; Type: function.
; Purpose: Read Themis/asi calibration data for given site(s).
;   Source: http://themis.ssl.berkeley.edu/data/themis.
; Parameter:
;   tr0, dummy variable, required. Keep the interface of sread_xxx uniform.
;   site0, in, strarr[n], required. The site(s).
; Keywords:
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   type, in, string, optional. 'ast','asf','asc', default is 'asc'.
;   version, in, string, optional. Data version. In case to load an old
;       version data. By default, the highest version is loaded.
; Return: struct.
; Notes: none.
; Dependence: slib.
; History:
;   2015-07-03, Sheng Tian, create.
;-
function sread_thg_asc, tr0, site0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type0, version = version
    
    compile_opt idl2
    
    ; local and remote directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('themis')
    if n_elements(remroot) eq 0 then $
        remroot = 'http://themis.ssl.berkeley.edu/data/themis'
    
    
    ; **** prepare site names.
    nsite = n_elements(site0)
    if nsite eq 0 then site0 = '*'
    if site0[0] eq '*' then begin
        site0 = ['atha','chbg','ekat','fsmi','fsim','fykn',$
            'gako','gbay','gill','inuv','kapu','kian',$
            'kuuj','mcgr','pgeo','pina','rank','snkq',$
            'tpas','whit','yknf','nrsq','snap','talo']
        nsite = n_elements(site0)
    endif
    sites = site0
    
    
    ; **** prepare file names.
    type = n_elements(type0)? type0[0]: 'asc'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'
    
    remfns = strarr(nsite)
    locfns = strarr(nsite)
    for i = 0, nsite-1 do begin
        baseptn = 'thg_l2_asc_'+sites[i]+'_19700101_'+vsn+'.'+ext
        rempaths = [remroot,'thg/l2/asi/cal',baseptn]
        locpaths = [locroot,'thg/l2/asi/cal',baseptn]
        remfns[i] = sprepfile(paths = rempaths)
        locfns[i] = sprepfile(paths = locpaths)
    endfor    

    for i = 0, nsite-1 do begin
        basefn = file_basename(locfns[i])
        locpath = file_dirname(locfns[i])
        rempath = file_dirname(remfns[i])
        locfns[i] = sgetfile(basefn, locpath, rempath)
    endfor
    idx = where(locfns ne '', nfn)
    if nfn ne 0 then locfns = locfns[idx] else return, -1
    
    
    ;**** prepare var names.
    if n_elements(var0s) eq 0 then begin
        var0s = ['glat','glon']
        if n_elements(var1s) eq 0 then var1s = ['glat','glon']
    endif
    if n_elements(var1s) eq 0 then var1s = idl_validname(var0s)
    var1s = idl_validname(var1s)
    
    
    ; **** module for variable loading.
    nvar = n_elements(var0s)
    if nvar ne n_elements(var1s) then message, 'mismatch var names ...'
    ptrs = ptrarr(nvar)
    ; first site.
    var2s = 'thg_'+type+'_'+sites[0]+'_'+var0s
    tmp = scdfread(locfns[0], var2s, 0, /silent)
    for j = 0, nvar-1 do ptrs[j] = (tmp[j].value)
    dat = create_struct(var1s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var1s[j], *ptrs[j])
    asc = create_struct(sites[0], dat)
    nsite = n_elements(sites)
    for i = 1, nsite-1 do begin
        var2s = 'thg_'+type+'_'+sites[i]+'_'+var0s
        tmp = scdfread(locfns[i], var2s, 0, /silent)
        for j = 0, nvar-1 do ptrs[j] = (tmp[j].value)
        dat = create_struct(var1s[0],*ptrs[0])
        for j = 1, nvar-1 do dat = create_struct(dat, var1s[j], *ptrs[j])
        asc = create_struct(asc, sites[i], dat)
    endfor
    
    for j = 0, nvar-1 do ptr_free, ptrs[j]

    
    return, asc
end

site = ['tpas']
vars = ['binc','binr']
asc = sread_thg_asc(0, vars = vars, type = 'ast')
end
