;+
; Type: function.
; Purpose: Read Polar Hydra data for a time range. 
;   Source: ftp://cdaweb.gsfc.nasa.gov/pub/data/polar/hydra.
; Parameters:
;   tr0, in, double/string, req. Set the time.
;       For double, it's the unix time or UTC. For string, it's the 
;       formatted string accepted by stoepoch, e.g., 'YYYY-MM-DD/hh:mm'.
; Keywords:
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   type, in, string, optional. Data type. Supported type h0 and k0.
;       Default is h0.
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
;   2013-06-17, Sheng Tian, create.
;-
function sread_polar_hydra, tr0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot=locroot, remroot=remroot, type=type, version=version, _extra=ex

    compile_opt idl2
    
    ; local and remote directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('polar/hydra')
    if n_elements(remroot) eq 0 then $
        remroot = 'ftp://cdaweb.gsfc.nasa.gov/pub/data/polar/hydra'

    ; **** prepare file names.
    utr0 = tr0
    if n_elements(type) eq 0 then type = 'h0'   ; can be k0 or h0.
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'
    baseptn = 'po_'+type+'_hyd_yyyyMMdd_'+vsn+'.'+ext
    rempaths = [remroot,'hyd_'+type,'YYYY',baseptn]
    if type eq 'k0' then rempaths = [remroot,'hydra_'+type,'YYYY',baseptn]
    locpaths = [locroot,'hyd_'+type,'YYYY',baseptn]
    remfns = sprepfile(utr0, paths = rempaths)
    locfns = sprepfile(utr0, paths = locpaths)

    nfn = n_elements(locfns)
    locidx = 'SHA1SUM'
    for i = 0, nfn-1 do begin
        basefn = file_basename(locfns[i])
        locpath = file_dirname(locfns[i])
        rempath = file_dirname(remfns[i])
        locfns[i] = sgetfile(basefn, locpath, rempath, locidx = locidx, _extra=ex)
    endfor

    idx = where(locfns ne '', nfn)
    if nfn ne 0 then locfns = locfns[idx] else return, -1

    ; **** check record index. locfns, nfn, recs, and etrs.
    epvname = (type eq 'h0')? 'EPOCH': 'Epoch'
    if n_elements(tr0) eq 0 then begin  ; no time info.
        recs = lon64arr(nfn,2)-1    ; [-1,-1] means to read all records.
        etrs = dblarr(2)
        tmp = scdfread(locfns[0],epvname,0)
        ets = *(tmp[0].value) & ptr_free, tmp[0].value
        etrs[0] = ets[0]
        tmp = scdfread(locfns[nfn-1],epvname,-1)
        ets = *(tmp[0].value) & ptr_free, tmp[0].value
        etrs[1] = ets[0]
    endif else begin                    ; there are time info.
        if size(tr0,/type) eq 7 then tformat = '' else tformat = 'unix'
        etrs = stoepoch(tr0, tformat)
        flags = bytarr(nfn)             ; 0 for no record.
        recs = lon64arr(nfn,2)
        for i = 0, nfn-1 do begin
            tmp = scdfread(locfns[i],epvname)   ; read each file's epoch.
            ets = *(tmp[0].value) & ptr_free, tmp[0].value
            if n_elements(etrs) eq 1 then begin ; tr0 is time.
                tmp = min(ets-etrs,idx, /absolute)
                dr = sdatarate(ets)
                if abs(ets[idx]-etrs) gt dr then flags[i] = 0 else begin
                    flags[i] = 1b
                    recs[i,*] = [idx,idx]
                endelse
            endif else begin                    ; tr0 is time range.
                idx = where(ets ge etrs[0] and ets le etrs[1], cnt)
                if cnt eq 0 then flags[i] = 0 else begin
                    flags[i] = 1b
                    recs[i,*] = [idx[0],idx[cnt-1]]
                endelse
            endelse
        endfor
        idx = where(flags eq 1b, cnt)
        if cnt eq 0 then begin
            message, 'no data at given time ...', /continue
            return, -1
        endif else begin
            locfns = locfns[idx]
            recs = recs[idx,*]
        endelse
    endelse
    nfn = n_elements(locfns)

    ; **** prepare var names.
    if n_elements(var0s) eq 0 then begin
        case type of
            'h0': begin
                var0s = ['EPOCH','ELECTRON_DIFFERENTIAL_ENERGY_FLUX',$
                    'ION_DIFFERENTIAL_ENERGY_FLUX','ENERGY_ELE','ENERGY_ION']
                if n_elements(var1s) eq 0 then $
                    var1s = ['epoch','jee','jei','ene','eni'] & end
            'k0': begin
                var0s = ['Epoch','ELE_DENSITY','ELE_MEAN_ENERGY']
                if n_elements(var1s) eq 0 then $
                    var1s = ['epoch','nele','enele'] & end
            else: message, 'unknown data type ...'
        endcase
    endif
    if n_elements(var1s) eq 0 then var1s = idl_validname(var0s)
    var1s = idl_validname(var1s)

    ; **** module for variable loading.
    nvar = n_elements(var0s)
    if nvar ne n_elements(var1s) then message, 'mismatch var names ...'
    ptrs = ptrarr(nvar)
    ; first file.
    tmp = scdfread(locfns[0],var0s,recs[0,*])
    for j = 0, nvar-1 do ptrs[j] = (tmp[j].value)
    ; rest files.
    for i = 1, nfn-1 do begin
        tmp = scdfread(locfns[i],var0s,recs[i,*])
        for j = 0, nvar-1 do begin
            ; works for all dims b/c cdf records on the 1st dim of array.
            *ptrs[j] = [*ptrs[j],*(tmp[j].value)]
            ptr_free, tmp[j].value  ; release pointers.
        endfor
    endfor
    ; remove fill value.
    fillval = -1e31
    vars = ['ELECTRON_DIFFERENTIAL_ENERGY_FLUX','ION_DIFFERENTIAL_ENERGY_FLUX']
    for i = 0, n_elements(vars)-1 do begin
        idx = where(var0s eq vars[i], cnt) & idx = idx[0]
        if cnt eq 0 then continue
        idx2 = where(*ptrs[idx] eq fillval, cnt)
        if cnt ne 0 then (*ptrs[idx])[idx2] = !values.d_nan
    endfor
    ; move data to structure.
    dat = create_struct(var1s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var1s[j],*ptrs[j])
    for j = 0, nvar-1 do ptr_free, ptrs[j]

    return, dat
end
        

hydr = sread_polar_hydra(filename = $
    ['L:\data\polar\hydra\hyd_h0\1998\po_h0_hyd_19980323_v01.cdf'])
;hydr = sread_polar_hydra('1998-03-23')
;hydr = sread_polar_hydra('2004-11-07', type = 'k0')
;hydr = sread_polar_hydra([et1, et2]).
end
