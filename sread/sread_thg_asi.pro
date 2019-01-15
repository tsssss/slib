;+
; Type: function.
; Purpose: Read Themis/asi raw image from single site.
;   Source: http://themis.ssl.berkeley.edu/data/themis.
; Parameter:
;   tr0, in, double/string or dblarr[2]/strarr[2], req. If in double or
;       string, set the time; if in dblarr[2] or strarr[2], set the time range.
;       For double or dblarr[2], it's the unix time or UTC. For string or
;       strarr[2], it's the formatted string accepted by stoepoch, e.g.,
;       'YYYY-MM-DD/hh:mm'.
;   site0, in, string, required. The site name. Only 1 site!
; Keywords:
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   type, in, string, optional. 'ast','asf', default is 'asf'.
;   version, in, string, optional. Data version. In case to load an old
;       version data. By default, the highest version is loaded.
; Return: struct.
; Notes: none.
; Dependence: slib.
; History:
;   2015-07-03, Sheng Tian, create.
;-
function sread_thg_asi, tr0, site0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type0, version = version
    
    compile_opt idl2

    ; local and remote directory.
    sep = path_sep()
    if n_elements(locroot) eq 0 then locroot = spreproot('themis')
    if n_elements(remroot) eq 0 then $
        remroot = 'http://themis.ssl.berkeley.edu/data/themis'


    ; **** prepare file names.
    site = site0[0]
    type = n_elements(type0)? strlowcase(type0): 'ast'  ; can be 'ast','asf'.
    tfmt = (type eq 'asf')? 'yyyyMMddhh': 'yyyyMMdd'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'
    
    baseptn = 'thg_l1_'+type+'_'+site+'_'+tfmt+'_'+vsn+'.'+ext
    rempaths = [remroot,'thg/l1/asi',site,'YYYY/MM',baseptn]
    locpaths = [locroot,'thg/l1/asi',site,'YYYY/MM',baseptn]
    
    ; prepare locfns, nfn.
    det = (type eq 'ast')? 864000000d: 3600000d
    remfns = sprepfile(tr0, paths = rempaths, dt = det)
    locfns = sprepfile(tr0, paths = locpaths, dt = det)
    nfn = n_elements(locfns)
    for i = 0, nfn-1 do begin
        basefn = file_basename(locfns[i])
        locpath = file_dirname(locfns[i])
        rempath = file_dirname(remfns[i])
        locfns[i] = sgetfile(basefn, locpath, rempath)
    endfor
    idx = where(locfns ne '', nfn)
    if nfn ne 0 then locfns = locfns[idx] else return, -1
    
    ; load needed calibration data.
    if type eq 'ast' then begin
        vars = ['binc','binr']
        tmp = sread_thg_asc(0, site, vars = vars, type = 'ast')
        binc = tmp.(0).binc
        binr = tmp.(0).binr
        binc = binc-min(binc)
        binr = binr-min(binr)
        nc = max(binc)
        nr = max(binr)
    endif

    
    ; **** check record index, locfns, nfn, recs, and utrs.
    epvname = 'thg_'+type+'_'+site+'_time'
    if n_elements(tr0) eq 0 then begin  ; no time info.
        recs = lon64arr(nfn,2)-1    ; [-1,-1] means to read all records.
        utrs = dblarr(2)
        tmp = scdfread(locfns[0],epvname,0)
        uts = *(tmp[0].value) & ptr_free, tmp[0].value & utrs[0] = uts[0]
        tmp = scdfread(locfns[nfn-1],epvname,-1)
        uts = *(tmp[0].value) & ptr_free, tmp[0].value & utrs[1] = uts[0]
    endif else begin                    ; there are time info.
        if size(tr0,/type) eq 7 then tformat = '' else tformat = 'unix'
        utrs = sfmepoch(stoepoch(tr0, tformat),'unix')
        flags = bytarr(nfn)             ; 0 for no record.
        recs = lon64arr(nfn,2)
        for i = 0, nfn-1 do begin
            if locfns[i] eq '' then continue
            tmp = scdfread(locfns[i],epvname)   ; read each file's epoch.
            uts = *(tmp[0].value) & ptr_free, tmp[0].value
            if n_elements(utrs) eq 1 then begin ; tr0 is time.
                tmp = min(uts-utrs,idx, /absolute)
                dr = sdatarate(uts)
                if abs(uts[idx]-utrs) gt dr then flags[i] = 0 else begin
                    flags[i] = 1b
                    recs[i,*] = [idx,idx]
                endelse
            endif else begin                    ; tr0 is time range.
                idx = where(uts ge utrs[0] and uts le utrs[1], cnt)
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
    

    ;**** prepare var names.
    if n_elements(var0s) eq 0 then $
        var0s = 'thg_'+type+'_'+site+['','_time']
    if n_elements(var1s) eq 0 then var1s = ['img','utsec']
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
    var = 'thg_'+type+'_'+site+'_time'
    idx = where(var0s eq var, cnt) & idx = idx[0]
    nrec = n_elements(*ptrs[idx])
    var = 'thg_'+type+'_'+site
    idx = where(var0s eq var, cnt) & idx = idx[0]
    ; deal with ast, need to re-map the pixels.
    if type eq 'ast' then begin
        if cnt ne 0 then begin
            if nrec eq 1 then begin
                imgs = uintarr(nr,nc)
                tmp = *ptrs[idx]
                imgs[binr,binc] = tmp[*]
            endif else begin
                imgs = uintarr(nrec,nr,nc)
                for i = 0, nrec-1 do begin
                    tmp = reform((*ptrs[idx])[i,*,*])
                    img = reform(imgs[i,*,*])
                    img[binr,binc] = tmp[*]
                    imgs[i,*,*] = img
                endfor
            endelse
            *ptrs[idx] = imgs
        endif
    endif
    ; image processing?
    var = 'thg_'+type+'_'+site
    
    ; move data to structure.
    dat = create_struct(var1s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var1s[j],*ptrs[j])
    for j = 0, nvar-1 do ptr_free, ptrs[j]

    return, dat
end

white = 255
ct = 39
site = ['fsmi']
type = 'asf'
tr = '2013-05-01/08:55'
tr = ['2007-05-07/07:00','2007-05-07/08:00']

site = ['chbg']
tr = ['2013-06-07/04:45','2013-06-07/05:15']

asi = sread_thg_asi(tr, type=type, site)

rootdir = shomedir()+'/asi/'+site[0]
uts = asi.utsec
nrec = n_elements(uts)
tpos = [0,0,1,1]
for i = 0, nrec-1 do begin
    timg = reform(asi.img[i,*,*])
    timg *= 64d/(median(timg) > 1)
;    timg = bytscl(timg)
    timg = timg < 255
    imgsz = size(timg,/dimensions)
    ofn = rootdir+'/thg_'+type+'_'+time_string(uts[i],tformat='YYYY_MMDD_hhmm_ss')+'.png'
    sgopen, ofn, xsize = imgsz[0], ysize = imgsz[1]
    sgtv, timg, position = tpos, ct = ct
    sgclose
endfor

end