;+
; Type: function.
; Purpose: Read Polar orbit data for a time range.
;   Source: ftp://cdaweb.gsfc.nasa.gov/pub/data/polar/orbit.
; Parameters:
;   tr0, in, double/string, req. Set the time.
;       For double, it's the unix time or UTC. For string, it's the 
;       formatted string accepted by stoepoch, e.g., 'YYYY-MM-DD/hh:mm'.
; Keywords:
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   tflag, in, int, optional. 0: all records, 1: nearest rec, 2: exact rec.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   type, in, string, optional. Data type. Supported type at, or, pa.
;   version, in, string, optional. Data version. In case to load an old
;       version data. By default, the highest version is loaded.
;   vars, in, strarr[n], optional. Set the variables to be loaded. There are
;       default settings for each type of data, check skeleton file to find
;       the available variables.
;   newnames, in/out, strarr[n], optional. The variable names appeared in the
;       returned structure. Must be valid names for structure tags.
;   flag, in, string, optional. Set it to be 'def' or 'pre'.
; Return: struct.
; Notes: MLT is in [0,24].
; Dependence: slib.
; History:
;   2015-06-25, Sheng Tian, create.
;-
function sread_polar_orbit, tr0, filename = fn0, tflag = tflag, $
    vars = var0s, newnames = var1s, $
    flag = flag, $
    locroot = locroot, remroot = remroot, type = type, version = version0, $
    _extra = ex

    compile_opt idl2

    ; local and remote directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('polar/orbit')
    if n_elements(remroot) eq 0 then $
        remroot = 'ftp://cdaweb.gsfc.nasa.gov/pub/data/polar/orbit'

    ; **** prepare file names.
    ; prepare locfns, nfn.
    nfn = n_elements(fn0)
    if nfn gt 0 then begin      ; find locally.
        locfns = fn0
        for i = 0, nfn-1 do begin
            basefn = file_basename(locfns[i])
            locpath = file_dirname(locfns[i])
            locfns[i] = sgetfile(basefn, locpath)
        endfor
        idx = where(locfns ne '', nfn)
    endif
    
    if nfn eq 0 then begin      ; find remotely.
        if n_elements(type) eq 0 then type = 'or' ; can be 1min or 5min.
        vsn = (n_elements(version))? version: 'v[0-9]{2}'
        flg = (type eq 'pa')? 'def': 'pre'
        if keyword_set(flag) then flg = flag
        ext = 'cdf'
        locidx = 'SHA1SUM'
        
        baseptn = 'po_'+type+'_'+flg+'_YYYYMMDD_'+vsn+'.'+ext
        rempaths = [remroot,flg+'_'+type,'YYYY',baseptn]
        locpaths = [locroot,flg+'_'+type,'YYYY',baseptn]
        
        if type eq 'or' then begin
            locpaths =[locroot,'YYYY',baseptn]
            baseptn = 'po_or_sheng_YYYYMMDD_'+vsn+'.'+ext
        endif
        
        remfns = sprepfile(tr0, paths = rempaths)
        locfns = sprepfile(tr0, paths = locpaths)
        nfn = n_elements(locfns)
        for i = 0, nfn-1 do begin
            basefn = file_basename(locfns[i])
            locpath = file_dirname(locfns[i])
            rempath = file_dirname(remfns[i])
            locfns[i] = sgetfile(basefn, locpath, rempath, locidx = locidx, _extra=ex)
        endfor
    endif
    idx = where(locfns ne '', nfn)
    if nfn ne 0 then locfns = locfns[idx] else return, -1
    

    ; **** check record index. locfns, nfn, recs, and etrs.
    epvname = 'Epoch'
    if ~keyword_set(tflag) then tflag = 0
    if n_elements(tr0) eq 0 then begin  ; no time info.
        recs = lon64arr(nfn,2)-1    ; [-1,-1] means to read all records.
        etrs = dblarr(2)
        tmp = scdfread(locfns[0],epvname)
        ets = *(tmp[0].value)
        etrs[0] = ets[0]
        tmp = scdfread(locfns[nfn],epvname)
        ets = *(tmp[0].value)
        etrs[1] = ets[n_elements(ets)-1]
    endif else begin                    ; there are time info.
        if size(tr0,/type) eq 7 then tformat = '' else tformat = 'unix'
        etrs = stoepoch(tr0, tformat)
        flags = bytarr(nfn)             ; 0 for no record.
        recs = lon64arr(nfn,2)
        for i = 0, nfn-1 do begin
            tmp = scdfread(locfns[i],epvname)   ; read each file's epoch.
            ets = *(tmp[0].value) & ptr_free, tmp[0].value
            if n_elements(etrs) eq 1 then begin ; tr0 is time.
                if tflag eq 0 then begin    ; read all records.
                    flags[i] = 1b
                    recs[i,*] = [0,n_elements(ets)-1]
                endif else if tflag eq 1 then begin ; read rearest record.
                    tmp = min(ets-etrs,idx, /absolute)
                    dr = sdatarate(ets)
                    if abs(ets[idx]-etrs) gt dr then flags[i] = 0 else begin
                        flags[i] = 1b
                        recs[i,*] = [idx,idx]
                    endelse
                endif else if tflag eq 2 then begin
                    idx = where(ets eq etrs, cnt)
                    if cnt ne 0 then begin
                        flags[i] = 1b
                        recs[i,*] = [idx,idx]
                    endif
                endif else message, 'invalid time info flag ...'
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
            ; common vars: 'Epoch','GSE_POS','GSM_POS','GCI_POS', 'GSE_VEL',
            ; 'GSM_VEL','GCI_VEL','EDMLT_TIME','MAG_LATITUDE','L_SHELL'.
            'or': begin
                var0s = ['Epoch','GSE_POS','EDMLT_TIME','L_SHELL']
                if n_elements(var1s) eq 0 then $
                    var1s = ['epoch','pos_gse','mlt','lshell'] & end
            'at': begin
                var0s = ['Epoch','GCI_R_ASCENSION','GCI_DECLINATION']
                if n_elements(var1s) eq 0 then $
                    var1s = ['epoch','ra','dec'] & end
            'pa': begin
                var0s = ['Epoch','DSP_ANGLE']
                if n_elements(var1s) eq 0 then $
                    var1s = ['epoch','dsp'] & end
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
    dat = create_struct(var1s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var1s[j],*ptrs[j])
    for j = 0, nvar-1 do ptr_free, ptrs[j]

    return, dat
end

dat = sread_polar_orbit(['1998-10-01/23:55','1998-10-02/00:05'], $
    vars = ['Epoch','GCI_POS'])
end
