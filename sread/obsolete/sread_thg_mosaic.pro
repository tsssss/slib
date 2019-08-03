;+
; Type: function.
; Purpose: Read Themis/asi MLT image for given site(s) for a time range.
;   This version is for batch reading and saving, default is half.
;   Source: http://themis.ssl.berkeley.edu/data/themis.
;   tr0, in, double/string, req. Set the time.
;       For double, it's the unix time or UTC. For string, it's the 
;       formatted string accepted by stoepoch, e.g., 'YYYY-MM-DD/hh:mm'.
;
; minlat, strongly suggest to ignore or set to 50 (deg).
; height, strongly suggest to ignore or set to 110 (km).
; minelev, no need to set in most cases.
; weight, set to do illumination correction, on trial.
; dark, set to 30-50 to exclude trees, etc. default is 50.
; notop, set it to allow pixel value greater than 255.
;-

function sread_thg_mosaic, tr0, site0, exclude = exclude, $
    locroot = locroot, remroot = remroot, type = type0, version = version, $
    height = height, minelev = minelev, dark = dark, weight = weight, $
    minlat = minlat, notop = notop, $
    full = full, $
    cmlon = cmlon, cmidn = cmidn, $
    plot = plot, save = save, ofn = fn

    compile_opt idl2
    

    ; emission height and min geomagnetic latitude.
    if n_elements(height) eq 0 then height = 110D   ; km in altitude.
    if height ne 90 and height ne 110 and height ne 150 then $
        message, 'height can only be 90, 110, 150 km ...'
    if n_elements(minlat) eq 0 then minlat = 60d    ; degree.

    ; local and remote directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('themis')
    if n_elements(remroot) eq 0 then $
        remroot = 'http://themis.ssl.berkeley.edu/data/themis'

    ; max pixel value.
    top = 254

    ; choose thumbnail ast, or full res asf.
    type = n_elements(type0)? strlowcase(type0): 'asf'  ; can be 'ast','asf'.

    ; min elevation.
    if n_elements(minelev) eq 0 then begin
        if type eq 'ast' then minelev = -10
        if type eq 'asf' then minelev = 5
    endif
    
    ; dark threshold.
    if n_elements(dark) eq 0 then dark = keyword_set(weight)? 5d: 50d


; **** prepare site names.
    site0s = ['atha','chbg','ekat','fsmi','fsim','fykn',$
        'gako','gbay','gill','inuv','kapu','kian',$
        'kuuj','mcgr','pgeo','pina','rank','snkq',$
        'tpas','whit','yknf','nrsq','snap','talo']
    nsite = n_elements(site0)
    if nsite eq 0 then site0 = '*'
    if site0[0] eq '*' then begin
        site0 = site0s
        nsite = n_elements(site0)
    endif
    sites = site0
    
    ; exclude sites.
    for i = 0, n_elements(exclude)-1 do begin
        idx = where(sites eq exclude[i], tmp)
        if tmp gt 0 then sites[idx] = ''
    endfor
    idx = where(sites ne '', tmp)
    if tmp eq 0 then begin
        message, 'no site ...', /continue
        return, -1
    endif
    sites = sites[idx]
    nsite = n_elements(sites)

; **** prepare the records. ets, uts, nrec.
    dr = 3d     ; 3 sec for ast and asf.
    dut = (type eq 'asf')? 3600: 86400
    det = dut*1e3
    if size(tr0,/type) eq 7 then tformat = '' else tformat = 'unix'
    etr0 = stoepoch(tr0, tformat)
    utr0 = sfmepoch(etr0,'unix') & tmp = utr0
    utr0 = utr0-(utr0 mod dr)
    if n_elements(utr0) eq 1 then begin     ; single time.
        if (tmp[0] mod dr) gt 0.5*dr then utr0+= dr ; round into closest rec.
        uts = utr0
    endif else begin                        ; time range.
        if (tmp[1] mod dr) gt 0 then utr0[1]+= dr
        if (tmp[1] mod dut) eq 0 then utr0[1]-= dr   ; exclude widow rec.
        uts = smkarthm(utr0[0], utr0[1], dr, 'dx')
    endelse
    ets = stoepoch(uts, 'unix')
    nrec = n_elements(uts)
    ; add a warning on large time range.
    if nrec gt 28800d then begin
        message, 'Very large time range is set, are you sure to continue?', /continue
        stop
    endif

; **** type related vars.
    npx = (type eq 'asf')? 256: 32
    isz = (type eq 'asf')? 3*npx: 6*npx
    del = 0.5*isz
    midns = dblarr(nrec)
    imfs = keyword_set(full)? dblarr(nrec,isz,isz): dblarr(nrec,isz,ceil(0.5*isz))
    tfmt = (type eq 'asf')? 'yyyyMMddhh': 'yyyyMMdd'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'


; **** prepare calibration vars.
    ; find midnight mlon, in deg, use all available calib files. cmlon,cmidn.
    asc = sread_thg_asc(0, vars = ['mlon','midn','glat','glon'])
    cnt = n_elements(site0s)
    cmlon = fltarr(cnt)
    cmidn = fltarr(cnt)
    cglat = fltarr(cnt)
    cglon = fltarr(cnt)
    for i = 0, cnt-1 do begin
        cmlon[i] = asc.(i).mlon
        cglat[i] = asc.(i).glat
        cglon[i] = asc.(i).glon
        tmp = asc.(i).midn
        if tmp eq '     ' then cmidn[i] = !values.d_nan $
        else cmidn[i] = float(strmid(tmp,0,2))+float(strmid(tmp,3,2))/60.0
    endfor
    idx = sort(cmidn)
    cmlon = cmlon[idx] & cmidn = cmidn[idx]
    idx = where(finite(cmidn))
    cmlon = cmlon[idx] & cmidn = cmidn[idx]
    

    ; glat and glon of the sites' center, used to tell moon position.
    ; mlat, mlon for 'asf', to convert to mltimg.
    ; binr, binc for 'ast', to 'map' to mltimg.
    glats = fltarr(nsite) & glons = fltarr(nsite)
    for j = 0, nsite-1 do begin
        idx = where(sites[j] eq site0s)
        glats[j] = cglat[idx]
        glons[j] = cglon[idx]
    endfor
    ; mlon, mlat, elev of the pixels.
    if type eq 'asf' then begin
        vars = ['elev','mlat','mlon','multiply']
        asc = sread_thg_asc(0, sites, type = type, vars = vars)
        
        elevs = fltarr(nsite,npx,npx)
        mults = fltarr(nsite,npx,npx)
        mlats = fltarr(nsite,npx+1,npx+1)
        mlons = fltarr(nsite,npx+1,npx+1)
        hgtidx = where([90,110,150] eq height)
        
        for j = 0, nsite-1 do begin
            elev = asc.(j).elev
            mlat = asc.(j).mlat
            mlon = asc.(j).mlon
                        
            mlon = reform(mlon[hgtidx,*,*],[npx+1,npx+1])
            mlat = reform(mlat[hgtidx,*,*],[npx+1,npx+1])
            mult = asc.(j).multiply
            if keyword_set(weight) then mult = sin(elev*!dtor)
            
            elevs[j,*,*] = elev
            mults[j,*,*] = mult
            mlats[j,*,*] = mlat
            mlons[j,*,*] = mlon
        endfor
    endif else begin
        vars = ['elev','binr','binc']
        asc = sread_thg_asc(0, sites, type = type, vars = vars)
        
        elevs = fltarr(nsite,npx*npx)
        mults = fltarr(nsite,npx*npx)
        binrs = fltarr(nsite,npx*npx)
        bincs = fltarr(nsite,npx*npx)
        
        for j = 0, nsite-1 do begin
            elevs[j,*] = asc.(j).elev
            mults[j,*] = 1
            binrs[j,*] = asc.(j).binr
            bincs[j,*] = asc.(j).binc
        endfor
        
        nmlon = 300
        nmlat = 120
    endelse


; **** prepare uts. asifns, '' for not found.
    fnuts = (n_elements(utr0) eq 1)? (utr0-(utr0 mod dut)): (sbreaktr(utr0, dut))[0,*]
    fnets = stoepoch(fnuts,'unix')
    nfnet = n_elements(fnets)
    fnetidx = 0
    
    asifns = strarr(nsite)
    cdfids = lonarr(nsite)
    utptrs = ptrarr(nsite,/allocate_heap)

    remfns = strarr(nsite,nfnet)
    locfns = strarr(nsite,nfnet)
    for j = 0, nsite-1 do begin
        baseptn = 'thg_l1_'+type+'_'+sites[j]+'_'+tfmt+'_'+vsn+'.'+ext
        rempaths = [remroot,'thg/l1/asi',sites[j],'YYYY/MM',baseptn]
        locpaths = [locroot,'thg/l1/asi',sites[j],'YYYY/MM',baseptn]
        remfns[j,*] = sprepfile(utr0, paths = rempaths, dt = det)
        locfns[j,*] = sprepfile(utr0, paths = locpaths, dt = det)
    endfor

    for i = 0, nrec-1 do begin
        print, 'processing '+sfmepoch(ets[i])+' ...'
        
        ; check if need to renew filenames, cdfids, uts.
        if i eq 0 then loadflag = 1 else begin
            tfnet = fnets[fnetidx]
            tfnet = tfnet-(tfnet mod det)+det
            if stoepoch(uts[i],'unix') ge tfnet then begin
                loadflag = 1
                fnetidx+= 1
            endif
        endelse

        
        ; open cdfids, read the times at each site.
        if loadflag eq 1 then begin
            ; close old files.
            for j = 0, nsite-1 do if asifns[j] ne '' then cdf_close, cdfids[j]
            
            ; prepare asifns, cdfids.
            for j = 0, nsite-1 do begin
                ; test moon.
                if keyword_set(nomoon) then begin
                    tmp = smoon(ets[i], glats[j], glons[j], /degree)
                    if tmp gt minelev then begin
                        if asifns[j] ne '' then cdf_close, cdfids[j]
                        asifns[j] = ''
                        continue
                    endif
                endif
                
                ; download or load file.
                basefn = file_basename(locfns[j,fnetidx])
                locpath = file_dirname(locfns[j,fnetidx])
                rempath = file_dirname(remfns[j,fnetidx])
                asifns[j] = sgetfile(basefn, locpath, rempath)
                
                ; read the times.
                if asifns[j] eq '' then continue
                cdfids[j] = cdf_open(asifns[j])
                tvar = 'thg_'+type+'_'+sites[j]+'_time'
                cdf_control, cdfids[j], variable = tvar, get_var_info = tmp, $
                    /zvariable
                cdf_varget, cdfids[j], tvar, tmp, rec_count = tmp.maxrec+1, $
                    /zvariable
                *utptrs[j] = reform(tmp)
            endfor
        endif

        ; midn mlon in deg for current time.
        midn = interpol(cmlon, cmidn, (uts[i]/86400d mod 1)*24, /nan)
        midn = 0
        midns[i] = midn

        if type eq 'asf' then begin
            imf = dblarr(isz,isz)           ; photon count.
            imc = dblarr(isz,isz)           ; overlap count for photon count.
        endif else begin
            imf = dblarr(nmlon,nmlat)
            imc = dblarr(nmlon,nmlat)
        endelse
        
        ; loop through each site.
        for j = 0, nsite-1 do begin
            if asifns[j] eq '' then continue
            
            ; find the record to read.
            rec = where(*utptrs[j] eq uts[i], cnt)
            if cnt eq 0 then continue     ; no data for current time.
            
            ; read raw image.
            tvar = 'thg_'+type+'_'+sites[j]
            cdf_varget, cdfids[j], tvar, img, rec_start = rec, /zvariable
            
            ; prelim image processing.
            img = double(img)
            ; remove edge.
            if type eq 'asf' then begin
                edge = where(elevs[j,*,*] lt minelev or ~finite(elevs[j,*,*]))
                img[edge] = mean(img[0:10,0:10], /nan)
                ; crude corner average subtraction. use thg_asf_site_offset?
                img = img - img[0] > 0
            endif
            ; scale luminosity, adopted from thm_asi_merge_mosaic.
            img *= 64d/(median(img) > 1)
            if ~keyword_set(notop) then img <= top
            ; apply true weight.
            img *= mults[j,*,*]
            mult = mults[j,*,*] & mult = mult[*]
            
;            ; tmp.
;            if sites[j] eq 'pina' or sites[j] eq 'gill' then img *= 0.5
            
            ; convert to mlt image.
            if type eq 'asf' then begin
                ; convert lat/lon corner to x/y corner grid.
                lat = reform(mlats[j,*,*]) & lon = reform(mlons[j,*,*])
                r = (90-lat)/(90-minlat)
                t = (lon-(90+midn))*(!dpi/180)  ; need rot mid night to -y.
                xc = r*cos(t) & yc = r*sin(t)   ; xc,yc in [-1,1].
                ; bin x/y corner grid to uniform x/y center grid.
                xc = floor((xc+1)*del+0.5)
                yc = floor((yc+1)*del+0.5)
                ; get illuminated pixel index.
                idx = where(finite(elevs[j,*,*]) and elevs[j,*,*] gt minelev)
                for k = 0, n_elements(idx)-1 do begin
                    tk = idx[k]
                    if img[tk] le dark then continue
                    ; extract pixel corner.
                    tidx = array_indices([npx,npx],tk,/dimensions)
                    xcor = xc[tidx[0]:tidx[0]+1,tidx[1]:tidx[1]+1]
                    ycor = yc[tidx[0]:tidx[0]+1,tidx[1]:tidx[1]+1]

                    ib = max(xcor, min = ia)
                    jb = max(ycor, min = ja)
                    if max([ia,ib,ja,jb]) gt isz then continue  ; nan.
                    ia = ia > 0
                    ja = ja > 0
                    ib = ib < (isz-1) > ia
                    jb = jb < (isz-1) > ja
                    imc[ia:ib,ja:jb] += mult[tk]
                    imf[ia:ib,ja:jb] += img[tk]
                endfor
            endif else begin
                imc[binrs[j,*],bincs[j,*]] += 1
                imf[binrs[j,*],bincs[j,*]] += img
            endelse
        endfor
        imf = imf/imc
        
        if type eq 'ast' then begin
            lat = smkarthm(50,0.25,nmlat,'x0')
            lon = smkarthm(-130,0.6,nmlon,'x0')
            r = (90-lat)/(90-minlat) ## (fltarr(nmlon)+1)
            t = (lon-(90+midn))*(!dpi/180) # (fltarr(nmlat)+1)
            
            xc = round(r*cos(t)*(isz*0.5-1))+isz*0.5
            yc = round(r*sin(t)*(isz*0.5-1))+isz*0.5
            imf0 = imf
            
            idx = where(xc ge 0 and xc le isz-1 and yc ge 0 and yc le isz-1)
            xc = xc[idx]
            yc = yc[idx]
            imf0 = imf0[idx]
            
            imf = dblarr(isz,isz)
            imc = dblarr(isz,isz)
            
            for k = 0, n_elements(imf0)-1 do begin
                imf[xc[k],yc[k]] += imf0[k]
                imc[xc[k],yc[k]] += 1
            endfor
            
            idx = where(imc ne 0)
            imf[idx] = imf[idx]/imc[idx]
        endif
        if keyword_set(full) then imfs[i,*,*] = imf else imfs[i,*,*] = imf[*,0:ceil(isz*0.5)-1]
    endfor
    

    ; shrink data.
    imgsz = size(reform(imfs[0,*,*]), /dimensions)
    timf = total(imfs,1)
    pxidx = where(timf ne 0,npxid)
    nrec = n_elements(uts)
    moss = intarr(nrec,npxid)       ; shrinked mosaic images.
    for i = 0, nrec-1 do moss[i,*] = (reform(imfs[i,*,*]))[pxidx]
    imfs = 0                        ; release memory.

    ; make mlat, mlt. don't save mlon b/c it is changing, mlt+midn -> mlon.
    xc = smkarthm(-1d,1,isz,'n') # (dblarr(isz)+1)
    yc = smkarthm(-1d,1,isz,'n') ##(dblarr(isz)+1)
    r = sqrt(xc^2+yc^2)
    t = atan(yc, xc)
    mlat = 90-r*(90-minlat)         ; in deg.
    mlt = (t/!dpi*12+24) mod 24     ; in hour.
    mlat = (rotate(mlat,3))
    mlt = (rotate(mlt,3))
    if ~keyword_set(full) then begin
        mlat = mlat[*,0:ceil(isz*0.5)-1]
        mlt = mlt[*,0:ceil(isz*0.5)-1]
    endif
    mlat = mlat[pxidx]
    mlt = mlt[pxidx]
    
    ; save data.
    ; uts, mos, cmidns, minlat,  mlt, mlat.
    locroot = shomedir()
    if n_elements(fn) eq 0 then $
        fn = locroot+'/thg_'+type+'_mosaic_'+sfmepoch(etr0[0],'YYYY_MMDD_hhmm')+'.cdf'
    print, 'saving data to '+fn+' ...'
    cdfid = cdf_create(fn, /clobber)
    cdf_compression, cdfid, set_compression = 5, set_gzip_level = 9
    ; create vatt.
    attid = cdf_attcreate(cdfid, 'FIELDNAM', /variable_scope)
    attid = cdf_attcreate(cdfid, 'UNITS', /variable_scope)
    attid = cdf_attcreate(cdfid, 'DEPEND_0', /variable_scope)
    attid = cdf_attcreate(cdfid, 'DEPEND_1', /variable_scope)
    attid = cdf_attcreate(cdfid, 'DEPEND_2', /variable_scope)
    attid = cdf_attcreate(cdfid, 'DEPEND_3', /variable_scope)
    attid = cdf_attcreate(cdfid, 'DEPEND_4', /variable_scope)
    attid = cdf_attcreate(cdfid, 'CATDESC', /variable_scope)
    ; create var.
    vname = 'time' & dimvary = 0 & var = transpose(uts)
    extra = create_struct('cdf_epoch',1, 'recvary',1, 'zvariable',1, $
        'dimension',1)
    varid = cdf_varcreate(cdfid, vname, dimvary, _extra = extra)
    cdf_varput, cdfid, vname, var
    cdf_attput, cdfid, 'FIELDNAM', vname, 'ut'
    cdf_attput, cdfid, 'UNITS', vname, 'sec'
    cdf_attput, cdfid, 'CATDESC', vname, 'unit time in sec'
    
    vname = 'thg_mosaic' & dimvary = 1. & var = transpose(temporary(moss))
    extra = create_struct('cdf_float',1, 'recvary',1, 'zvariable',1, $
        'dimensions',n_elements(pxidx))
    varid = cdf_varcreate(cdfid, vname, dimvary, _extra = extra)
    cdf_compression, cdfid, variable = vname, $
        set_compression = 5, set_gzip_level = 9
    cdf_varput, cdfid, vname, var & var = 0
    cdf_attput, cdfid, 'FIELDNAM', vname, 'thg_mosaic'
    cdf_attput, cdfid, 'UNITS', vname, 'count'
    cdf_attput, cdfid, 'DEPEND_0', vname, 'time'
    cdf_attput, cdfid, 'DEPEND_1', vname, 'image_size'
    cdf_attput, cdfid, 'DEPEND_2', vname, 'pixel_index'
    cdf_attput, cdfid, 'DEPEND_3', vname, 'mlt'
    cdf_attput, cdfid, 'DEPEND_4', vname, 'mlat'
    cdf_attput, cdfid, 'CATDESC', vname, 'thg mosaic in mlt/mlat coord'
    
    vname = 'midn' & dimvary = 0 & var = transpose(midns)
    extra = create_struct('cdf_float',1, 'recvary',1, 'zvariable',1, $
        'dimensions',1)
    varid = cdf_varcreate(cdfid, vname, dimvary, _extra = extra)
    cdf_varput, cdfid, vname, var
    cdf_attput, cdfid, 'FIELDNAM', vname, 'midn'
    cdf_attput, cdfid, 'UNITS', vname, 'hr'
    cdf_attput, cdfid, 'DEPEND_0', vname, 'time'
    cdf_attput, cdfid, 'CATDESC', vname, 'mlt of midnight'
    
    vname = 'mlt' & dimvary = 1 & var = mlt
    extra = create_struct('cdf_float',1, 'recvary',0, 'zvariable',1, $
        'dimensions',size(var,/dimensions))
    varid = cdf_varcreate(cdfid, vname, dimvary, _extra = extra)
    cdf_varput, cdfid, vname, var
    cdf_attput, cdfid, 'FIELDNAM', vname, 'mlt'
    cdf_attput, cdfid, 'UNITS', vname, 'hr'
    cdf_attput, cdfid, 'CATDESC', vname, 'pixel mlt'
    
    vname = 'mlat' & dimvary = 1 & var = mlat
    extra = create_struct('cdf_float',1, 'recvary',0, 'zvariable',1, $
        'dimensions',size(var,/dimensions))
    varid = cdf_varcreate(cdfid, vname, dimvary, _extra = extra)
    cdf_varput, cdfid, vname, var
    cdf_attput, cdfid, 'FIELDNAM', vname, 'mlat'
    cdf_attput, cdfid, 'UNITS', vname, 'deg'
    cdf_attput, cdfid, 'CATDESC', vname, 'pixel mlat'
    
    vname = 'image_size' & dimvary = 1 & var = imgsz
    extra = create_struct('cdf_int4',1, 'recvary',0, 'zvariable',1, $
        'dimensions',size(var,/dimensions))
    varid = cdf_varcreate(cdfid, vname, dimvary, _extra = extra)
    cdf_varput, cdfid, vname, var
    cdf_attput, cdfid, 'FIELDNAM', vname, 'image size in pixel'
    cdf_attput, cdfid, 'CATDESC', vname, '[xsize,ysize]'
    
    vname = 'pixel_index' & dimvary = [1,1] & var = pxidx
    extra = create_struct('cdf_uint4',1, 'recvary',0, 'zvariable',1, $
        'dimensions',size(var,/dimensions))
    varid = cdf_varcreate(cdfid, vname, dimvary, _extra = extra)
    cdf_varput, cdfid, vname, var
    cdf_attput, cdfid, 'FIELDNAM', vname, 'pixel index'
    cdf_attput, cdfid, 'CATDESC', vname, 'index of non-zero pixels'
    
    vname = 'minlat' & dimvary = 0 & var = minlat
    extra = create_struct('cdf_float',1, 'recvary',0, 'zvariable',1, $
        'dimensions',1)
    varid = cdf_varcreate(cdfid, vname, dimvary, _extra = extra)
    cdf_varput, cdfid, vname, var
    cdf_attput, cdfid, 'FIELDNAM', vname, 'minlat'
    cdf_attput, cdfid, 'UNITS', vname, 'deg'
    cdf_attput, cdfid, 'CATDESC', vname, 'min latitude in deg'
    
    cdf_close, cdfid
    
    return, fn
end

type = 'asf'

;tr = ['2013-05-01/04:00','2013-05-01/10:00']
;tr = ['2013-05-01/07:00','2013-05-01/07:00:06']
;sites = ['tpas','atha']


tr = ['2013-05-01/07:37','2013-05-01/07:39']
sites = ['*']
type = 'ast'


tr = ['2014-12-22/02:28:06','2014-12-22/02:28:09']
sites = ['kuuj']
type = 'asf'
minlat = 55d
fn = sread_thg_mosaic(tr, sites, type='asf', minlat=minlat, dark=0, /notop)

cdfs = scdfread(fn)

uts = (*cdfs[0].value)
mos = (*cdfs[1].value)
midn= (*cdfs[2].value)
mlt = (*cdfs[3].value)
mlat= (*cdfs[4].value)
imgsz = (*cdfs[5].value)
pxidx = (*cdfs[6].value)
minlat = (*cdfs[7].value)

img = fltarr(imgsz)
nrec = n_elements(uts)

sgopen, 1, xsize = imgsz[0]*1, ysize = imgsz[1]*1
loadct, 1
for i = 0, nrec-1 do begin
    timg = img
    timg[pxidx] = mos[i,*]
    timg = bytscl(timg, min=10, max=200, top=254, /nan)
    sgtv, timg, position = [0,0,1,1], ct=1
    wait, 0.5
    stop
endfor
sgclose
end
