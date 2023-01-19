;+
; Type: function.
; Purpose: Read Polar UVI MLT image for a time range.
;   Source: ftp://cdaweb.gsfc.nasa.gov/pub/data/polar/uvi.
; Parameters:
;   tr0, in, double/string, req. Set the time.
;       For double, it's the unix time or UTC. For string, it's the 
;       formatted string accepted by stoepoch, e.g., 'YYYY-MM-DD/hh:mm'.
; Keywords:
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   type, in, string, dummy. Force type = uvi_level1.
;   version, in, string, optional. Data version. In case to load an old
;       version data. By default, the highest version is loaded.
;   height, in, double, optional. Aurora emission height in km. 110 by default.
;   minlat, in, double, optional. Minimum latitude in absolute value in degree.
;       50 by default.
;   apexfile, in string, optional. The file stores lat/lon in apex mag coord.
;   vars, in, strarr[n], dummy. Don't use, dummy keywords to keep uniform with
;       other sread_xxx_xxx routines.
;   newnames, in/out, strarr[n], dummy. The variable names appeared in the
;       returned structure. Must be valid names for structure tags. Force to be
;       ['epoch','intimg','mltimg'].
; Return: struct.
; Notes: none.
; Dependence: slib.
; History:
;   2013-06-17, Sheng Tian, create.
;-
function sread_polar_uvi, tr0, filename = fn0, $
    vars = var0s, newnames = var1s, get_filename = getfn, $
    locroot = locroot, remroot = remroot, type = type, version = version, $
    height = height, minlat = minlat, apexfile = apexfile, half = half
    
    compile_opt idl2

    ; emission height and min geomagnetic latitude.
    if n_elements(height) eq 0 then height = 110d   ; km in altitude.
    if n_elements(minlat) eq 0 then minlat = 50d    ; degree.

    ; local and remote directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('polar/uvi')
    if n_elements(remroot) eq 0 then $
        remroot = 'ftp://cdaweb.gsfc.nasa.gov/pub/data/polar/uvi'

    ; apex file.
    if n_elements(apexfile) eq 0 then $ ; load data once?
        apexfile = srootdir()+'/support/mlatlon.1997a.xdr'

    ; **** prepare file names.
    utr0 = tr0
    type = 'level1'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'
    baseptn = 'po_'+type+'_uvi_yyyyMMdd_'+vsn+'.'+ext
    rempaths = [remroot,'uvi_'+type,'yyyy',baseptn]
    locpaths = [locroot,'uvi_'+type,'yyyy',baseptn]
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

    if keyword_set(getfn) then return, locfns


    ; **** check record index. locfns, nfn, recs, and etrs.
    epvname = 'EPOCH'
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
            if locfns[i] eq '' then continue    ; file does not exist.
            tmp = scdfread(locfns[i],epvname)   ; read each file's epoch.
            ets = *(tmp[0].value)
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

    ; **** prepare auxilliary data: orbit, attitude, platform attitude.
    axetrs = [sepochfloor(etrs[0]),sepochceil(etrs[n_elements(etrs)-1])]
    axutrs = sfmepoch(axetrs,'unix')
    orb = sread_polar_orbit(axutrs, type='or',vars=['Epoch','GCI_POS'],$
        newnames=['epoch','orbit'])
    att = sread_polar_orbit(axutrs, type='at',vars=['Epoch','GCI_R_ASCENSION',$
        'GCI_DECLINATION'],newnames=['epoch','ra','dec'])
    pat = sread_polar_orbit(axutrs, type='pa',vars=['Epoch','DSP_ANGLE'],$
        newnames=['epoch','dsp'])
    pat.dsp = pat.dsp*(180d/!dpi)
    idx = where(abs(pat.dsp) le 180, cnt)
    if cnt eq 0 then begin
        message, 'no valid despun angle ...', /continue
        return, -1
    endif
    pat = {epoch:pat.epoch[idx], dsp:pat.dsp[idx]}

    ; **** prepare var names.
    var2s = ['EPOCH','INT_IMAGE','FILTER','FRAMERATE','SYSTEM']
    var3s = idl_validname(var2s)
    ; ['epoch','intmg','mltimg','glat','glon','mlat','mlon','mlt']?
    if n_elements(var1s) eq 0 then var1s = ['epoch','intimg','mltimg']
    var1s = idl_validname(var1s)

    ; **** module for variable loading.
    nvar = n_elements(var2s)
    if nvar ne n_elements(var3s) then message, 'mismatch var names ...'
    ptrs = ptrarr(nvar)
    ; first file.
    tmp = scdfread(locfns[0],var2s,recs[0,*])
    for j = 0, nvar-1 do ptrs[j] = (tmp[j].value)
    ; rest files.
    for i = 1, nfn-1 do begin
        tmp = scdfread(locfns[i],var2s,recs[i,*])
        for j = 0, nvar-1 do begin
            ; works for all dims b/c cdf records on the 1st dim of array.
            *ptrs[j] = [*ptrs[j],*(tmp[j].value)]
            ptr_free, tmp[j].value  ; release pointers.
        endfor
    endfor
    dat = create_struct(var3s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var3s[j],*ptrs[j])
    for j = 0, nvar-1 do ptr_free, ptrs[j]
    
    ; **** int_img to mlt_img, get glon/glat, mlon/mlat, mlt_img.
    nrec = n_elements(dat.epoch)
    if n_elements(imgsz) eq 0 then imgsz = 4*(90-minlat) else imgsz -= 1
    mltimgs = keyword_set(half)? $
        intarr(nrec,imgsz+1,imgsz/2+1): intarr(nrec,imgsz+1,imgsz+1)
    for i = 0, nrec-1 do begin
        tet = dat.epoch[i]
        print, sfmepoch(tet,'yyyy-MM-dd hh:mm:ss.fff')
        
        img = (nrec eq 1)? dat.int_image: reform(dat.int_image[i,*,*])
        fet = tet-floor((dat.framerate[i]+4)*9.2)*1000d     ; frame time.

        ; interpolate the despun angle at the frame time.
        idx = where(pat.epoch ge fet and pat.epoch le tet, cnt)
        if cnt le 3 then begin
            tmp = min(pat.epoch-fet, rec, /absolute)
            idx = rec+[-1,0,1]
        endif
        ; make sure idx is valid.
        tmp = idx[0] & if tmp lt 0 then idx-= tmp
        tmp = idx[n_elements(idx)-1]-n_elements(pat.epoch)
        if tmp ge 0 then idx-= tmp
        if max(pat.epoch[idx]) lt fet then continue     ; no extrapolate.
        if min(pat.epoch[idx]) gt fet then continue
        ; use psl file to correct? see get_dsp_angles.pro.
        tdsp = spl_interp(pat.epoch[idx],pat.dsp[idx], $
            spl_init(pat.epoch[idx],pat.dsp[idx]), fet)

        ; GCI pos at frame time in km. no intepolation?
        tmp = min(orb.epoch-fet, rec, /absolute)
        torb = reform(orb.orbit[rec,*])
        ; sphere. 1: north, 0: south.
        sphere = torb[2] gt 0

        ; attitude at frame time. no interpolation?
        tmp = min(att.epoch-fet, rec, /absolute)
        tatt = [cos(att.dec[rec])*cos(att.ra[rec]),cos(att.dec[rec])*$
            sin(att.ra[rec]),sin(att.dec[rec])]

        ; system id. 0:primary, 1:secondary.
        tsys = dat.system[i]+1

        ; calculate glat/glon, from looking direction at frame time.
        polar_uvilook, torb,tatt,tdsp,dat.filter[i], lookdir, system = tsys
        polar_ptg, fet, height,tatt,torb,tsys,lookdir, glat,glon, /geodetic
            
        ; do line-of-sight and dayglow correction.
;        polar_uvi_corr, fet,torb,tsys, glat,glon, img
            
        ; get mlat/mlon, use geo2apex.
        geo2apex, glat, glon, apexfile, mlat, mlon
        get_local_time, fet, glat, glon, glt, mlt
        get_mlt_image, img, mlat, mlt, minlat, sphere, mltimg, ncell = imgsz
        if keyword_set(half) then mltimgs[i,*,*] = mltimg[*,0:imgsz/2] $
        else mltimgs[i,*,*] = mltimg
    endfor
    
    dat = {epoch:reform(dat.epoch), mltimg:reform(mltimgs), img:reform(dat.int_image)}
    return, dat
end

t0 = ('1997-05-01/20:22:20')    ; wygant.
;;et = stoepoch('1997-05-01/20:25:20')    ; wygant.
;;et = stoepoch('1997-05-01/20:32:00')    ; wygant.
;;et = stoepoch('1997-05-09/05:44:50')    ; wygant.
;;et = stoepoch('1997-05-09/05:42:50')    ; wygant.
;;et = stoepoch('1997-05-01/10:25:29')
;;et = stoepoch('1997-05-01/17:18:52')
;t0 = '1997-05-01/19:31:60'
;t0 = '1997-05-01/20:22:30'
;t0 = '2007-03-24/07:40'
;t0 = '2006-08-20/17:00'
;t0 = '2006-04-05/14:30'
;t0 = '2006-04-09/09:00'
;t0 = '2007-04-01/08:20'
;t0 = '2006-01-02/03:04'
;t0 = '2006-01-05/04:38'
;t0 = '2006-01-11/07:22'
;t0 = '2006-02-14/20:01'
;;t0 = ['1998-02-12/00:00','1998-02-13/00:00']
dat = sread_polar_uvi(t0)
xsz = 300 & ysz = 300
img = congrid(reform(dat.mltimg), xsz, ysz, /interp)
sz = size(img,/dimensions)
window, 0, xsize = sz[0], ysize = sz[1]
sgindexcolor, 43, file = 'ct2'
tv, img
end
