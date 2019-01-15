;+
; Type: function.
; Purpose: Read Polar MFE data for a time range. 
;   Source: ftp://cdaweb.gsfc.nasa.gov/pub/data/polar/mfe.
; Parameters:
;   tr0, in, double/string, req. Set the time.
;       For double, it's the unix time or UTC. For string, it's the 
;       formatted string accepted by stoepoch, e.g., 'YYYY-MM-DD/hh:mm'.
; Keywords:
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   type, in, string, dummy. k0.
;   version, in, string, optional. Data version. In case to load an old
;       version data. By default, the highest version is loaded.
;   vars, in, strarr[n], optional. Set the variables to be loaded. There are
;       default settings for each type of data, check skeleton file to find
;       the available variables.
;   newnames, in/out, strarr[n], optional. The variable names appeared in the
;       returned structure. Must be valid names for structure tags.
; Return: struct.
; Notes: none.
; Dependence: slib.
; History:
;   2016-09-08, Sheng Tian, create.
;-
function sread_polar_mfe, tr0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type, version = version

    compile_opt idl2
    
    ; local and remote directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('polar/mfe')
    if n_elements(remroot) eq 0 then $
        remroot = 'ftp://cdaweb.gsfc.nasa.gov/pub/data/polar/mfe'

    ; **** prepare file names.
    utr0 = tr0
    type = 'k0'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'
    baseptn = 'po_'+type+'_mfe_yyyyMMdd_'+vsn+'.'+ext
    rempaths = [remroot,'mfe_'+type,'YYYY',baseptn]
    locpaths = [locroot,'mfe_'+type,'YYYY',baseptn]
    remfns = sprepfile(utr0, paths = rempaths)
    locfns = sprepfile(utr0, paths = locpaths)

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
    if n_elements(var0s) eq 0 then begin
        var0s = ['Epoch','B_GSM','POS_GSM']
    endif
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
    ; remove fill value.

    ; move data to structure.
    dat = create_struct(var1s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var1s[j],*ptrs[j])
    for j = 0, nvar-1 do ptr_free, ptrs[j]

    return, dat
end
        

mfe = sread_polar_mfe('1998-10-01')

end
