;+
; Type: function.
; Purpose: Read Omni 1min data from CDAWeb:
;   ftp://cdaweb.gsfc.nasa.gov/pub/data/omni/omni_cdaweb/.
; Parameters: none.
; Keywords:
;   var0s, in, strarr[n], opt. Default is Epoch, AE_INDEX, SYM_H, Pressure,
;       BX_GSE, BY_GSE, BZ_GSE, flow_speed, Vy, Vz, proton_density.
;   type, in, string, opt. Can be 1min, 5min. Default is 1min.
; Return:
;   return, out, struct.
; Notes:
;   * Choose to set either fn0 or t0, don't set or omit them both.
;   * To use, need to set "pattern" of file name, see L59 and sptn2fn.pro.
;   * There are other variables in the cdf file.
; Dependence: slib.
; History:
;   2013-06-18, Sheng Tian, create.
;-
function sread_omni, tr0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type0, version = version
    
    compile_opt idl2
    
    ; local and remote directory.
    if n_elements(locroot) eq 0 then locroot = $
        spreproot('omni/omni_cdaweb')
    if n_elements(remroot) eq 0 then remroot = $
        'ftp://cdaweb.gsfc.nasa.gov/pub/data/omni/omni_cdaweb'


    ; **** prepare file names.
    type = (n_elements(type0))? type0: '1min'
    prb = (n_elements(probe0))? probe0: 'a'
    vsn = (n_elements(version))? version: 'v[0-9.]{2}'
    ext = 'cdf'
    
    ; type1 in filename, type2 in path.
    type1 = 'hro_'+type
    type2 = 'hro_'+type
    
    baseptn = 'omni_'+type1+'_YYYYMM01_'+vsn+'.'+ext
    rempaths = [remroot,type2,'YYYY',baseptn]
    locpaths = [locroot,type2,'YYYY',baseptn]
    
    remfns = sprepfile(tr0, paths = rempaths)
    locfns = sprepfile(tr0, paths = locpaths)
    nfn = n_elements(locfns)
    for i = 0, nfn-1 do begin
        basefn = file_basename(locfns[i])
        locpath = file_dirname(locfns[i])
        rempath = file_dirname(remfns[i])
        locfns[i] = sgetfile(basefn, locpath, rempath, remidx = 'SHA1SUM')
    endfor
    idx = where(locfns ne '', nfn)
    if nfn ne 0 then locfns = locfns[idx] else return, -1
    
    
    ; **** prepare var names.
    if n_elements(var0s) eq 0 then begin
        var0s = ['Epoch','AE_INDEX','SYM_H','Pressure','BX_GSE','BY_GSE','BZ_GSE',$
            'flow_speed','Vy','Vz','proton_density']
        var1s = idl_validname(var0s)
    endif
    if n_elements(var1s) eq 0 then var1s = idl_validname(var0s)
    var1s = idl_validname(var1s)


    ; **** module for variable loading.
    nvar = n_elements(var0s)
    if nvar ne n_elements(var1s) then message, 'mismatch var names ...'
    ptrs = ptrarr(nvar)
    ; first file.
    tmp = scdfread(locfns[0],var0s, skt = skt)
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
    
    ; remove fillval.
    varnames = tag_names(skt.var)
    for j = 0, nvar-1 do begin
        idx = where(varnames eq strupcase(var0s[j]))
        fillval = skt.var.(idx).att.fillval.value
        idx = where(dat.(j) eq fillval, cnt)
        if cnt eq 0 then continue
        tmp = dat.(j)
        tmp[idx] = !values.f_nan
        dat.(j) = tmp
    endfor
    
    ; trim to time range.

    return, dat
end

omni = sread_omni(['1998-10-01','1998-10-01/01:00'])
end