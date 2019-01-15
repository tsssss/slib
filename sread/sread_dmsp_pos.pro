;+
; load DMSP position in GEO [lat, lon, dis].
;-
function sread_dmsp_pos, tr0, probes = probe0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type0, version = version

    compile_opt idl2

;---local and remote directory.
    sep = path_sep()
    if n_elements(locroot) eq 0 then locroot = spreproot('dmsp')
    if n_elements(remroot) eq 0 then $
        remroot = 'ftp://cdaweb.gsfc.nasa.gov/pub/data/dmsp'
    
;---prepare file names.
    type1 = 'ssm'
    prb = (n_elements(probe0))? probe0: 'f18'
    vsn = (n_elements(version))? version: 'v[0-9.]{5}'
    ext = 'cdf'

    baseptns = ['dmsp-'+prb+'_ssm_magnetometer_','YYYYMMDD_'+vsn+'.'+ext]
    nbaseptn = n_elements(baseptns)
    ptnflags = [0,1]
    rempaths = [remroot+'/dmsp'+prb+'/'+type1+'/magnetometer','YYYY',baseptns]
    locpaths = [locroot+'/dmsp/'+prb+'/'+type1,'YYYY',baseptns]
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
    if n_elements(var0s) eq 0 then begin
        ; other options: SC_AACGM_[LAT,LON,LTIME], SC_APEX_[LAT,LON,MLT], SC_ECI.
        var0s = ['Epoch','SC_GEOCENTRIC_'+['LAT','LON','R']]    ; 'geo'.
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

    ; trim to the wanted time range.
    if n_elements(tr0) eq 2 then begin
        tformat = (size(tr0,/type) eq 7)? '': 'unix'
        etr0 = stoepoch(tr0, tformat)
        epvars = ['Epoch']   ; the epoch vars.
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

;---finish.
    return, dat

end

utr = time_double(['2013-06-07','2013-06-07/12:00'])
pos = sread_dmsp_pos(utr, probes = 'f18')
end