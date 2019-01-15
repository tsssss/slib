;+
; Type: function.
; Purpose: Read FAST TEAMS data for a time range.
; Parameters: 
;   tr0, in, double/string, req. Set the time.
;       For double, it's the unix time or UTC. For string, it's the 
;       formatted string accepted by stoepoch, e.g., 'YYYY-MM-DD/hh:mm'.
; Keywords: 
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   type, in, string, dummy. Data type. Default is k0.
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
;   2015-05-04, Sheng Tian, create.
;   2017-09-19, Sheng Tian, re-written.
;-

function sread_fast_tms, tr0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type, version = version
    
    compile_opt idl2
    
    ; local and remote root directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('fast/teams')
    if n_elements(remroot) eq 0 then $
        remroot = 'ftp://cdaweb.gsfc.nasa.gov/pub/data/fast/teams'

    ; **** prepare file names.
    utr0 = tr0
    type = 'k0'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'
    baseptn = 'fa_'+type+'_tms_YYYYMMDD_'+vsn+'.'+ext
    rempaths = [remroot,type,'YYYY',baseptn]
    locpaths = [locroot,type,'YYYY',baseptn]
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
    if n_elements(var0s) eq 0 then $
        ; 'H+_low','H+_low_pa', etc.
        var0s = ['Epoch','H+','H+_en','O+','O+_en']
    if n_elements(var1s) eq 0 then var1s = idl_validname(var0s,/convert_all)
    var1s = idl_validname(var1s,/convert_all)
    

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

    fillval = -1e31
    for j = 0, nvar-1 do begin
        idx = where(dat.(j) eq fillval, cnt)
        if cnt eq 0 then continue
        tmp = dat.(j)
        tmp[idx] = !values.d_nan
        dat.(j) = tmp
    endfor

    return, dat

end

lim = {spec:1,ylog:1,zlog:1, xstyle:1, ystyle:1, no_interp:1}
utr = time_double(['1998-10-01/02:05','1998-10-01/02:20'])
utr = time_double(['1998-09-25/04:25','1998-09-25/04:40'])

tms = sread_fast_tms(utr)
uts = sfmepoch(tms.epoch,'unix')
store_data, 'h_en', uts, tms.h_, tms.h__en, limits=lim
store_data, 'o_en', uts, tms.o_, tms.o__en, limits=lim

vars = ['h','o']+'_en'
device, decomposed = 0 & loadct2, 43
tplot, vars, trange=utr




end
