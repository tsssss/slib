;+
; Run rbsp_hope_l2_calc_and_save_moments first.
;-

function sread_rbsp_hope_moments, tr0, probes = probe0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type0, version = version

    compile_opt idl2

;---local and remote directory.
    sep = path_sep()
    if n_elements(locroot) eq 0 then locroot = sdiskdir('Research')+'/sdata/rbsp'
    
;---prepare file names.
    type1 = 'hope_moment'
    type2 = 'hope_moments'
    prb = (n_elements(probe0))? probe0: 'a'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'

    baseptns = ['rbsp'+prb+'_'+type2,'_YYYY_MMDD_'+vsn+'.'+ext]
    nbaseptn = n_elements(baseptns)
    ptnflags = [0,1]
    locpaths = [locroot+'/rbsp'+prb+'/'+type1,'YYYY',baseptns]
    ptnflags = [0,1,ptnflags]

    locfns = sprepfile(tr0, paths = locpaths, flags=ptnflags, nbase=nbaseptn)
    nfn = n_elements(locfns)
    for i = 0, nfn-1 do begin
        basefn = file_basename(locfns[i])
        locpath = file_dirname(locfns[i])
        locfns[i] = sgetfile(basefn, locpath)
    endfor
    if keyword_set(fn0) then locfns = file_search(fn0)
    idx = where(locfns ne '', nfn)    
    if nfn ne 0 then locfns = locfns[idx] else return, -1
    
;---prepare var names.
    if n_elements(var0s) eq 0 then begin
        ; [e,p,o,he]_[density,t_avg,vbulk,number_flux,energy_flux,enthalpy].
        vars = ['density','t_avg','vbulk','number_flux','energy_flux','enthalpy']
        var0s = ['ut_ion','ut_ele', 'e_'+vars, 'p_'+vars, 'o_'+vars, 'he_'+vars]
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
        utvars = 'ut_'+['ion','ele']
        allvars = tag_names(skt.var)
        nallvar = n_elements(allvars)
        ; check each of the epoch vars.
        for i = 0, n_elements(utvars)-1 do begin
            idx = (where(var0s eq utvars[i], cnt))[0]
            if cnt eq 0 then continue   ; didn't read a epoch var.
            ets = *(ptrs[idx])          ; the epochs.
            tidx = where(ets ge tr0[0] and ets le tr0[1]) ; epoch idx.
            *ptrs[idx] = (*ptrs[idx])[tidx] ; trim the epoch var.
            ; check the other var0s.
            for j = 0, n_elements(var0s)-1 do begin
                vinfo = skt.var.(where(allvars eq strupcase(var0s[j]))).att
                vatts = tag_names(vinfo)
                deps = where(strpos(vatts,'DEPEND_') ne -1, cnt)
                if cnt eq 0 then continue   ; do not depend on other vars.
                for k = 0, cnt-1 do begin
                    if vinfo.(deps[k]).value ne utvars[i] then continue
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
