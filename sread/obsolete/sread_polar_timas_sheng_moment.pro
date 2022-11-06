;+
; load Polar TIMAS moments calculated by Sheng Tian.
;-

function sread_polar_timas_sheng_moment, tr0, filename=fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type, version = version, $
    _extra = ex
    
    compile_opt idl2
    
;---local and remote directory.
    sep = path_sep()
    if n_elements(locroot) eq 0 then locroot = sdiskdir('Research')+'/sdata/polar/timas'
    if n_elements(remroot) eq 0 then remroot = ''

;---prepare file names.
    ext = 'cdf'

    baseptns = ['po_tim_moments_','YYYY_MMDD','.'+ext]
    nbaseptn = n_elements(baseptns)
    ptnflags = [0,1,0]
    locpaths = [locroot,'YYYY',baseptns]
    ptnflags = [0,1,ptnflags]

    locfns = sprepfile(tr0, paths = locpaths, flags=ptnflags, nbase=nbaseptn)
    nfn = n_elements(locfns)
    for i = 0, nfn-1 do begin
        basefn = file_basename(locfns[i])
        locpath = file_dirname(locfns[i])
        locfns[i] = sgetfile(basefn, locpath, _extra=ex)
    endfor
    idx = where(locfns ne '', nfn)    
    if nfn ne 0 then locfns = locfns[idx] else return, -1


;---prepare var names.
    if n_elements(var0s) eq 0 then begin
        var0s = ['ut_sec','h_density','h_energy_flux']
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
    ; skip for small files.

    ; move data to structure.
    dat = create_struct(var1s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var1s[j],*ptrs[j])
    for j = 0, nvar-1 do ptr_free, ptrs[j]

;---finish.
    return, dat
    

end

utr = time_double('1996-03-17')
dat = sread_polar_timas_sheng_moment(utr)
end
