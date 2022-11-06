;+
; Type: function.
; Purpose: Read HOPE level 2 data.
;   Source: http://www.rbsp-ect.lanl.gov/data_pub
;   Backup: ftp://cdaweb.gsfc.nasa.gov/pub/data/rbsp
; Parameters:
;   tr0, in, double/string or dblarr[2]/strarr[2], req. If in double or
;       string, set the time; if in dblarr[2] or strarr[2], set the time range.
;       For double or dblarr[2], it's the unix time or UTC. For string or
;       strarr[2], it's the formatted string accepted by stoepoch, e.g.,
;       'YYYY-MM-DD/hh:mm'.
; Keywords:
;   probes, in, string or strarr[2], opt. 'a','b',['a','b']. Default is 'a'.
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   type, in, string, optional. 'rel02','rel03'.
;   version, in, string, optional. Data version. In case to load an old
;       version data. By default, the highest version is loaded.
;   vars, in, strarr[n], optional. The vars to be loaded.
;   newnames, in, strarr[n], optional. The new names for the vars.
; Return: struct.
; Notes: none.
; History:
;   2016-02-12, Sheng Tian, create.
;-

function sread_rbsp_hope_l2, tr0, probes = probe0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type0, version = version
    
    compile_opt idl2
    
    ; local and remote directory.
    sep = path_sep()
    if n_elements(locroot) eq 0 then locroot = spreproot('rbsp')
    if n_elements(remroot) eq 0 then $
        remroot = 'ftp://cdaweb.gsfc.nasa.gov/pub/data/rbsp'

    ; **** prepare file names.
    if n_elements(type0) eq 0 then type = 'rel03' else type = strlowcase(type0)
    prb = (n_elements(probe0))? probe0: 'a'
    vsn = (n_elements(version))? version: 'v[0-9.]{5}'
    ext = 'cdf'
    
    baseptn = 'rbsp'+prb+'_'+type+'_ect-hope-sci-l2_YYYYMMDD_'+vsn+'.'+ext
    ;rempaths = [remroot,'rbsp'+prb,'l2','ect','hope','sci',type,'YYYY',baseptn]
    rempaths = [remroot, 'rbsp'+prb,'l2','ect','hope','sectors',type,'YYYY',baseptn]
    locpaths = [locroot,'rbsp'+prb,'hope/level2/YYYY',baseptn]

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
    if nfn eq 0 then begin  ; try another source at lanl.
        remroot = 'http://www.rbsp-ect.lanl.gov/data_pub'
        baseptn = 'rbsp'+prb+'_'+type+'_ect-hope-sci-L2_YYYYMMDD_'+vsn+'.'+ext
        rempaths = [remroot,'rbsp'+prb,'hope/level2/'+strupcase(type),baseptn]
        locpaths = [locroot,'rbsp'+prb,'hope/level2/YYYY',baseptn]
        
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
    endif
    if nfn ne 0 then locfns = locfns[idx] else return, -1
        
    
    ; **** prepare var names.
    if n_elements(var0s) eq 0 then $
        var0s = ['Epoch',$
            'Epoch_Ele','Epoch_Ele_DELTA','HOPE_ENERGY_Ele',$
            'Epoch_Ion','Epoch_Ion_DELTA','HOPE_ENERGY_Ion',$
            'Sector_Collapse_Cntr','Energy_Collapsed',$
            'FPDU','FODU','FHEDU','FEDU']
    if n_elements(var1s) eq 0 then var1s = idl_validname(var0s)
    var1s = idl_validname(var1s)
    
    ; **** module for variable loading.
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
    
    ; trim to the wanted time range.
    if n_elements(tr0) eq 2 then begin
        tformat = (size(tr0,/type) eq 7)? '': 'unix'
        etr0 = stoepoch(tr0, tformat)
        epvars = ['Epoch_Ele','Epoch_Ion','Epoch']   ; the epoch vars.
        allvars = tag_names(skt.var)
        nallvar = n_elements(allvars)
        ; check each of the epoch vars.
        for i = 0, n_elements(epvars)-1 do begin
            idx = (where(var0s eq epvars[i], cnt))[0]
            if cnt eq 0 then continue   ; didn't read a epoch var.
            ets = *(ptrs[idx])          ; the epochs.
            tidx = where(ets ge etr0[0] and ets le etr0[1]) ; epoch idx.
            *ptrs[idx] = (*ptrs[idx])[tidx] ; trim the epoch var.
            ; check the other var0s.
            for j = 0, n_elements(var0s)-1 do begin
                vinfo = skt.var.(where(allvars eq strupcase(var0s[j]))).att
                vatts = tag_names(vinfo)
                deps = where(strpos(vatts,'DEPEND_') ne -1, cnt)
                if cnt eq 0 then continue   ; do not depend on other vars.
                for k = 0, cnt-1 do begin
                    if vinfo.(deps[k]).value ne epvars[i] then continue
                    *ptrs[j] = (*ptrs[j])[tidx,*,*,*,*,*,*,*]
                endfor
            endfor
        endfor
    endif
    
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

;    vars = tag_names(dat)
;    
;    ; coef for each energy bin and pixel bin.
;    tmp = sdiskdir('Research')+'/data/rbsp/hope_coef.sav'
;    if file_test(tmp) ne 0 then begin
;        restore, filename = tmp
;        j = where(vars eq 'FPDU', cnt)
;        if cnt ne 0 then begin
;            tmp = dat.(j)
;            for i = 0, 71 do $
;                for j = 0, 4 do tmp[*,i,*,j]*= coef_proton[i,j]
;        endif
;    endif

    ; the simple version, coef for pixel bin.
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
hopel2 = sread_rbsp_hope_l2(utr, probes = 'a')
end
