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

function sread_rbsp_emfisis, tr0, probes = probe0, filename = fn0, $
    coord = coord, $
    locroot = locroot, remroot = remroot, type = type, version = version

    compile_opt idl2
    
        
    ; **** prepare file names.
    if n_elements(type) eq 0 then type = 'L3'   ; can be level[2,3].
    prb = (n_elements(probe0))? probe0: 'a'
    vsn = (n_elements(version))? version: 'v[0-9.]{5}'
    crd = (n_elements(coord))? coord: 'gse'
    ext = 'cdf'
    
    rempath = 'http://emfisis.physics.uiowa.edu/Flight/RBSP-'+strupcase(prb)+'/'+type+'/YYYY/MM/DD/'
    locpath = sdiskdir('Research')+'/data/rbsp/rbsp'+prb+'/emfisis/'+type+'/YYYY/'
    baseptn = 'rbsp-'+prb+'_magnetometer_1sec-'+crd+'_emfisis-'+type+'_YYYYMMDD_'+vsn+'.'+ext

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
        var0s = ['Epoch','Mag']
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

    return, dat

end

utr = time_string(['2013-05-19'])
emfisis = sread_rbsp_emfisis(utr)
end
