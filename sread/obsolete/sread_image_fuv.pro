;+
; Type: function.
; Purpose: Read IMAGE FUV MLT image for a time range. 
;   Source: ftp://cdaweb.gsfc.nasa.gov/pub/data/image/fuv.
; Parameters:
;   tr0, in, double/string, req. Set the time.
;       For double, it's the unix time or UTC. For string, it's the 
;       formatted string accepted by stoepoch, e.g., 'YYYY-MM-DD/hh:mm'.
; Keywords:
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   type, in, string, optional. 'wic' by default, can be 'sie','sip','wic'.
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
;   spin, in, float, opt. Camera spin phase in degree. Manually adjust when cdf
;       contains wrong spin phase info.
; Return: struct.
; Notes: Set horizontal field of view equal to vertical, because sometimes hfov
;   is wrong. Not sure if should multiply or divide fov scale.
;       azim, elev, roll are contained in the cdf file but sometimes are wrong,
;   better to get them using
; Dependence: slib.
; History:
;   2009-04-01, Sheng Tian, create.
;   2015-03-04, Sheng Tian, re-write.
;-

function sread_image_fuv, tr0, filename = fn0, $
    spin = spins, dspin = dspin, $
    vars = var0s, newnames = var1s, get_filename = getfn, $
    locroot = locroot, remroot = remroot, type = type, version = version, $
    height = height, minlat = minlat, apexfile = apexfile, half = half

    compile_opt idl2

    ; emission height and min geomagnetic latitude.
    if n_elements(height) eq 0 then height = 130d   ; km in altitude.
    if n_elements(minlat) eq 0 then minlat = 50d    ; degree.

    ; local and remote directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('image/fuv')
    if n_elements(remroot) eq 0 then $
        remroot = 'ftp://cdaweb.gsfc.nasa.gov/pub/data/image/fuv'

    ; apex file.
    if n_elements(apexfile) eq 0 then $ ; load data once?
        apexfile = srootdir()+'/support/mlatlon.1997a.xdr'

    ; **** prepare file names.
    utr0 = tr0
    type = (n_elements(type) eq 0)? 'wic': strlowcase(type)
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'
    baseptn = 'im_k0_'+type+'_yyyyMMdd_'+vsn+'.'+ext
    rempaths = [remroot,type+'_k0','yyyy',baseptn]
    locpaths = [locroot,type+'_k0','yyyy',baseptn]
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
    
    
    ; fix instrument azimuth, co elevation, and roll angle, vfov, hfov.
    for i = 0, nfn-1 do begin
        var2s = ['EPOCH','INST_AZIMUTH','INST_CO_ELEVATION','INST_ROLL','INSTRUMENT_ID','VFOV','HFOV']
        tmp = scdfread(locfns[i],var2s)
        tet = (*tmp[0].value)[0]
        nrec = n_elements(*tmp[0].value)
        if n_elements(*tmp[5].value) eq nrec then continue  ; has been fixed.
        
        ang0s = reform([*tmp[1].value,*tmp[2].value,*tmp[3].value])
        instr = strtrim(*tmp[4].value,2)
        vfov = reform(*tmp[5].value)
        hfov = reform(*tmp[6].value)
        
        cdf_epoch, tet, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
        rootdir = srootdir()+'/support/image'
        tmp = where(instr eq ['WIC','SI1356','SI1218'])
        image_get_inst_angles_p, tmp, yr, stodoy(yr,mo,dy), ang1s, rootdir
        
        if max(abs(ang1s-ang0s)) eq 0 then continue
        
        ; update angles and version.
        var2s = ['INST_AZIMUTH','INST_CO_ELEVATION','INST_ROLL','VFOV','HFOV']
        vals = [ang1s,vfov,hfov]
        for j = 0, n_elements(var2s)-1 do $
            scdfwrite, locfns[i], var2s[j], value = replicate(vals[j],nrec), /reset
    endfor


    ; **** prepare auxilliary data and var names. 
    tmp = (type eq 'wic')? 'WIC': 'SI' & tmp+= '_PIXELS'
    var2s = ['EPOCH',tmp,'INSTRUMENT_ID','VFOV','HFOV','FOVSCALE', $
        'SV_'+['X','Y','Z'], 'SPINPHASE', 'ORB_'+['X','Y','Z'], $
        'SCSV_'+['X','Y','Z'], $
        'INST_AZIMUTH','INST_CO_ELEVATION','INST_ROLL']
    var3s = idl_validname(var2s)
    var3s[1] = 'INT_IMAGE'
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

    
    if n_elements(spins) ne 0 then dat.spinphase = spins
    if n_elements(dspin) ne 0 then dat.spinphase+= dspin

    ; **** int_img to mlt_img, get glon/glat, mlon/mlat, mlt_img.
    nrec = n_elements(dat.epoch)
;    if nrec gt 10 then dat.spinphase = smooth(dat.spinphase,5)
    if n_elements(imgsz) eq 0 then imgsz = 4*(90-minlat) else imgsz -= 1
    mltimgs = keyword_set(half)? $
        intarr(nrec,imgsz+1,imgsz/2+1): intarr(nrec,imgsz+1,imgsz+1)
    for i = 0, nrec-1 do begin
        tet = dat.epoch[i]
        print, sfmepoch(tet,'yyyy-MM-dd hh:mm:ss.fff')
        
        img = (nrec eq 1)? dat.int_image: reform(dat.int_image[i,*,*])
        if type eq 'wic' then img = float(reverse(rotate(img,1),2)) else img = float(rotate(img,3))
        npx = (size(img, /dimensions))[0]
        instr = strtrim(dat.instrument_id[i],2)
        vfov = dat.vfov[i]
        hfov = dat.hfov[i]
        fovscl = dat.fovscale[i]
        hfov = hfov*fovscl/npx
        vfov = vfov*fovscl/npx
        sv = reform([dat.sv_x[i],dat.sv_y[i],dat.sv_z[i]])
        spinphase = dat.spinphase[i]
        orbit = reform([dat.orb_x[i],dat.orb_y[i],dat.orb_z[i]])
        scsv = reform([dat.scsv_x[i],dat.scsv_y[i],dat.scsv_z[i]])

        ; instrument azimuth, co elevation, and roll angle.
        azim = dat.inst_azimuth[i]
        elev = dat.inst_co_elevation[i]
        roll = dat.inst_roll[i]

        ; get pointing info, glat/glon.
        cdf_epoch, tet, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
        time = lonarr(2)
        time[0] = yr*1000L+stodoy(yr,mo,dy)
        time[1] = 1000L*(sc+60*(mi+60*hr))+msc     ; mili second of day.
        image_ptg, height, sv, orbit, scsv, $
            spinphase, time, npx, npx, vfov, hfov, azim, elev, roll, $
            glat, glon  ; output
        glat[where(abs(glat) gt 1e20)] = !values.d_nan
        glon[where(abs(glon) gt 1e20)] = !values.d_nan

        ; other info.
        sphere = orbit[2] gt 0

        geo2apex, glat, glon, apexfile, mlat, mlon
        get_local_time, tet, glat, glon, glt, mlt
        get_mlt_image, img, mlat, mlt, minlat, sphere, mltimg, ncell = imgsz
        
;        tvscl, mlat, 0, /nan
;        tvscl, mlt, 1, /nan
;        tvscl, img, 2, /nan
;        tvscl, mltimg, /nan
        
        if keyword_set(half) then mltimgs[i,*,*] = mltimg[*,0:imgsz/2] $
        else mltimgs[i,*,*] = mltimg
    endfor

    dat = {epoch:reform(dat.epoch), mltimg:reform(mltimgs), img:reform(dat.int_image)}
    return, dat

end

fpn = spreproot('image')+'/fuv/wic_k0/2000/im_k0_wic_20001203_v01.cdf'
utr = time_double(['2001-10-22/07:50','2001-10-22/08:40'])
;utr = '2001-10-22/08:19:39'
wic = sread_image_fuv(utr, /half, /get_filename)
;wic = read_image_fuv(stoepoch('2000-12-03/15:10'))
end
