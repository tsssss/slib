;+
; Type: function.
; Purpose: Read Polar timas data for a time range.
;   Source: ftp://cdaweb.gsfc.nasa.gov/pub/data/polar/timas.
; Parameters:
;   tr0, in, double/string, req. Set the time.
;       For double, it's the unix time or UTC. For string, it's the 
;       formatted string accepted by stoepoch, e.g., 'YYYY-MM-DD/hh:mm'.
; Keywords:
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   type, in, string, optional. Data type. Supported type h0 and k1.
;       h2 data for before 1999-01-01, k1 for after 1998-12-31.
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
;-
function sread_polar_timas, tr0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type, version = version, $
    _extra = ex
    
    compile_opt idl2
    
    ; local and remote root directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('polar/timas')
    if n_elements(remroot) eq 0 then $
        remroot = 'https://cdaweb.gsfc.nasa.gov/pub/data/polar/timas'
    
    ; **** prepare file names.
    utr0 = tr0
    if n_elements(type) eq 0 then type = 'k1'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'
    baseptn = 'po_'+type+'_tim_YYYYMMDD_'+vsn+'.'+ext
    rempaths = [remroot,'timas_'+type,'YYYY',baseptn]
    locpaths = [locroot,'timas_'+type,'YYYY',baseptn]
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

    ; **** prepare var names.
    if n_elements(var0s) eq 0 then begin
        case type of
            'k1': begin
                var0s = ['Epoch','Flux_H','Flux_O','Flux_He_1','Flux_He_2','energy']
                end
            'h0': begin
                var0s = ['Epoch_H','Epoch_O','Epoch_He_1','Epoch_He_2', $
                    'Flux_H','Flux_O','Flux_He_1','Flux_He_2','energy','angle']
                end
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
    fillval = 0
    vars = ['Epoch_H','Epoch_O','Epoch_He_1','Epoch_He_2']
    for i = 0, n_elements(vars)-1 do begin
        idx = where(var0s eq vars[i], cnt) & idx = idx[0]
        if cnt eq 0 then continue
        idx2 = where(*ptrs[idx] eq fillval, cnt)
        if cnt ne 0 then (*ptrs[idx])[idx2] = !values.d_nan
    endfor
    
    filval = -1e31
    for i = 0, n_elements(var0s)-1 do begin
        idx = where(*ptrs[i] le fillval, cnt)
        if cnt ne 0 then (*ptrs[i])[idx] = !values.d_nan
    endfor
    
    ; move data to structure.
    dat = create_struct(var1s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var1s[j],*ptrs[j])
    for j = 0, nvar-1 do ptr_free, ptrs[j]

    return, dat
end

tr = ['1998-10-01/02:00','1998-10-01/04:30']
tr = ['1998-09-25/05:00','1998-09-25/06:00']

utr = time_double(tr)
;tms = sread_polar_timas(['1998-09-25'], type = 'h0')
tms = sread_polar_timas(utr, type = 'h0')

pre = 'en'
idx = 3
opt = {spec:1,ylog:1,zlog:1, xstyle:1, ystyle:1,no_interp:1}

c = 1d/4/!dpi/2

tmp = total(tms.flux_h,idx,/nan)
tvar = pre+'fh'
for i = 0, n_elements(tms.energy)-1 do tmp[*,i]*=tms.energy[i]*1e-3*c
store_data, tvar, sfmepoch(tms.epoch_h,'unix'), tmp, tms.energy, limits = opt
options, tvar, 'ytitle', 'TIMAS H+!Cenergy (eV)'

tmp = total(tms.flux_o,idx,/nan)
tvar = pre+'fo'
for i = 0, n_elements(tms.energy)-1 do tmp[*,i]*=tms.energy[i]*1e-3*c
store_data, tvar, sfmepoch(tms.epoch_o,'unix'), tmp, tms.energy, limits = opt
options, tvar, 'ytitle', 'TIMAS O+!Cenergy (eV)'

tmp = total(tms.flux_he_1,idx,/nan)
tvar = pre+'fhe1'
for i = 0, n_elements(tms.energy)-1 do tmp[*,i]*=tms.energy[i]*1e-3*c
store_data, tvar, sfmepoch(tms.epoch_he_1,'unix'), tmp, tms.energy, limits = opt
options, tvar, 'ytitle', 'TIMAS He+!Cenergy (eV)'

tmp = total(tms.flux_he_2,idx,/nan)
tvar = pre+'fhe2'
for i = 0, n_elements(tms.energy)-1 do tmp[*,i]*=tms.energy[i]*1e-3*c
store_data, tvar, sfmepoch(tms.epoch_he_2,'unix'), tmp, tms.energy, limits = opt
options, tvar, 'ytitle', 'TIMAS He++!Cenergy (eV)'

hyd = sread_polar_hydra(utr)
tvar = 'hydra'
store_data, tvar, sfmepoch(hyd.epoch,'unix'), hyd.jei, hyd.eni, limits = opt
options, tvar, 'ytitle', 'Hydra H+!Cenergy (eV)'

vars = ['enfh','enfo','enfhe1','enfhe2','hydra']
zlim, vars, 1e4, 1e8, 1
ylim, vars, 20, 2e4, 1
options, vars, 'ztitle', 'Log#!C/cm!U2!N-s-sr'

pre = 'pa'
idx = 2
opt = {spec:1,ylog:0,zlog:1, xstyle:1, ystyle:1,no_interp:1}
store_data, pre+'fh', sfmepoch(tms.epoch_h,'unix'), $
    total(tms.flux_h,idx,/nan), tms.angle, limits = opt
store_data, pre+'fo', sfmepoch(tms.epoch_o,'unix'), $
    total(tms.flux_o,idx,/nan), tms.angle, limits = opt
store_data, pre+'fhe1', sfmepoch(tms.epoch_he_1,'unix'), $
    total(tms.flux_he_1,idx,/nan), tms.angle, limits = opt
store_data, pre+'fhe2', sfmepoch(tms.epoch_he_2,'unix'), $
    total(tms.flux_he_2,idx,/nan), tms.angle, limits = opt
zlim, vars, 1e4, 1e8, 1
options, vars, 'ztitle', 'Log#!C/cm!U2!N-s-sr'


vars = ['enfh','enfo','enfhe1','enfhe2','pafh','pafo','pafhe1','pafhe2']
vars = ['enfh','enfo','enfhe1','enfhe2','hydra']
device, decomposed = 0 & loadct2, 43
tplot, vars, trange = utr
end
