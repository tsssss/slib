;+
; Type: function.
; Purpose: Read Themis/asi MLT image for given site(s) for a time range.
;   Source: http://themis.ssl.berkeley.edu/data/themis.
; Parameter:
;   tr0, in, double/string, req. Set the time.
;       For double, it's the unix time or UTC. For string, it's the 
;       formatted string accepted by stoepoch, e.g., 'YYYY-MM-DD/hh:mm'.
;   site0, in, strarr[n], optional. The sites to be included. Include all sites
;       by default.
; Keywords:
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   type, in, string, optional. Can be 'asf' and 'ast'. Default is 'asf'.
;   version, in, string, optional. Data version. In case to load an old
;       version data. By default, the highest version is loaded.
;   exclude, in, strarr[m], optional. The sites to be excluded. No site is
;       excluded by default.
;   height, in, double, optional. Aurora emission height in km. 110 by default.
;   minlat, in, double, optional. Minimum latitude in absolute value in degree.
;       50 by default.
;   weight, in, boolean, optional. Set to apply a weight to the raw image on
;       all sites. The weight is sin(elevation).
;   minelev, in, double, optional. Threshold for elevation, pixels that have
;       smaller elevation will be thrown away.
;   dark, in, double, optional. Threshold for darkness, pixels that have value
;       less than dark will be thrown away. The default value is 5 if weight is
;       set, is 50 if weight is not set. Reasonable value is 30-50.
;   half, in, boolean, optional. Set to return the night half of the MLT image.
;   notop, in, boolean, optional. Set to remove top limit of 255.
; Return: struct. {epoch: epoch, mltimg: mltimg}.
; Notes: none.
; Dependence: slib.
; History:
;   2013-09-06, Sheng Tian, create.
;-
function sread_thg_mlt, tr0, site0, exclude = exclude, $
    vars = var0s, newnames = var1s, nomoon = nomoon, $
    locroot = locroot, remroot = remroot, type = type0, version = version, $
    height = height, minlat = minlat, minelev = minelev, $
    dark = dark, weight = weight, half = half, notop = notop, $
    cmlon = cmlon, cmidn = cmidn

    compile_opt idl2

    ; emission height and min geomagnetic latitude.
    if n_elements(height) eq 0 then height = 110d   ; km in altitude.
    if height ne 90 and height ne 110 and height ne 150 then $
        message, 'height can only be 90, 110, 150 km ...'
    if n_elements(minlat) eq 0 then minlat = 50d    ; degree.

    ; local and remote directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('themis')
    if n_elements(remroot) eq 0 then $
        remroot = 'http://themis.ssl.berkeley.edu/data/themis'

    ; max pixel value.
    top = 254

    ; choose thumbnail ast, or full res asf.
    type = n_elements(type0)? strlowcase(type0): 'asf'  ; can be 'ast','asf'.
    
    ; min elevation, points below minelev is thrown away.
    if n_elements(minelev) eq 0 then begin
        if type eq 'ast' then minelev = -10
        if type eq 'asf' then minelev = 5
    endif
    
    ; dark threshold, points less than dark is thrown away.
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
    
    print, 'reading sites: '+strjoin(sites,',')+' ...'

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
    isz = (type eq 'asf')? 3*npx: 8*npx
    del = 0.5*isz
    imfs = keyword_set(half)? $
        dblarr(nrec,isz,ceil(0.5*isz)): dblarr(nrec,isz,isz)
    tfmt = (type eq 'asf')? 'yyyyMMddhh': 'yyyyMMdd'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'

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
    


; **** prepare calibration vars. elevs, mults,
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
    fnets = (n_elements(etr0) eq 1)? (etr0-(etr0 mod det)): $
        reform((sbreaktr(etr0, det))[0,*])
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
        ; check if need to renew filenames, cdfids, uts.
        loadflag = (i eq 0)? 1: 0
        if stoepoch(uts[i],'unix') ge fnets[fnetidx]+det then begin
            loadflag = 1
            fnetidx+= 1
        endif
        
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
                        print, sites[j]+' has moon ...'
                        continue
                    endif
                endif
                
                ; download or load file.
                basefn = file_basename(locfns[j,fnetidx])
                locpath = file_dirname(locfns[j,fnetidx])
                rempath = file_dirname(remfns[j,fnetidx])
                asifns[j] = sgetfile(basefn, locpath, rempath)
                
                ; read the times.
                if asifns[j] eq '' then begin
                    print, sites[j]+' no data ...'
                    continue
                endif
                print, sites[j]+' has data ...'
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
;            if max(img) gt 1e4 then img*= 0.5
            if ~keyword_set(notop) then img <= top
            ; apply true weight.
            img *= mults[j,*,*]
            mult = mults[j,*,*] & mult = mult[*]
            
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
            
            imf = imf/imc
        endif
        if keyword_set(half) then imfs[i,*,*] = imf[*,0:ceil(isz*0.5)-1] $
        else imfs[i,*,*] = imf
    endfor

    ; **** cleanup.
    for j = 0, nsite-1 do begin
        ptr_free, utptrs[j]
        if asifns[j] ne '' then cdf_close, cdfids[j]
    endfor
    
    ets = stoepoch(uts,'unix')
    return, {epoch:reform(ets),mltimg:reform(imfs)}

end

; asi = sread_thg_mlt('2013-05-01/07:38', type='ast', /weight, exclude = ['fsmi','fsim','snkq'], /half)
asi = sread_thg_mlt('2007-03-11/10:06', type='asf', /half)

;asi = sread_thg_mlt('2013-05-01/07:38', type='asf', /weight, ['kapu'])
;asi = sread_thg_mlt(['2007-03-24/07:40:12','2007-03-24/07:40:15'], type = 'asf', /weight, ['gill','tpas','atha','gako','whit','inuv'], /nomoon)

xsz = 400 & ysz = xsz*0.5
device, decomposed = 0
loadct, 39, /silent

if size(asi.mltimg,/n_dimensions) eq 2 then begin
    img = asi.mltimg
    sz = size(img,/dimensions)
    img = congrid(img, xsz, ysz, /interp)
    window, 1, xsize = xsz, ysize = ysz
    tv, img
endif else begin
    for i = 0, n_elements(asi.epoch)-1 do begin
        img = reform(asi.mltimg[i,*,*])
        sz = size(img,/dimensions)
        img = congrid(img, xsz, ysz, /interp)
        window, 1, xsize = xsz, ysize = ysz
        tv, img
        wait, 0.5
    endfor
endelse
end
