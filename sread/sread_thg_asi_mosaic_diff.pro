;-
; Calculate the differential image for mosaic images.
;+
function sread_thg_asi_mosaic_diff, tr0, site0, filename = fn0, $
    locroot = locroot, remroot = remroot, type = type0, version = version, $
    height = height, minelev = minelev, dark = dark, weight = weight, $
    plot = plot, save = save, ofn = fn
    
    compile_opt idl2
    
    ; load the compressed version of aurora images.
    load = 0
    if n_elements(fn0) eq 0 then load = 1 $
    else if file_test(fn0) eq 0 then load = 1
    
    if load eq 1 then begin
        if n_elements(tr0) ne 2 then message, 'invalid time info ...'
        if n_elements(fn0) eq 0 then begin
            if n_elements(rootdir) eq 0 then $
                rootdir = sdiskdir('Research')+'/sdata'
            if n_elements(type0) eq 0 then type = 'asf'
            fn0 = rootdir+'/themis/thg/mosaic/thg_'+type+'_mosaic_'+$
                time_string(tr0[0],tformat='YYYY_MMDD_hhmm')+'_to_'+$
                time_string(tr0[1],tformat='hhmm')
        endif
        fn0 = sread_thg_mosaic(tr0, site0, exclude = exclude, $
            locroot = locroot, remroot = remroot, type = type, $
            version = version, height = height, minelev = minelev, $
            dark = dark, weight = weight, save = save, ofn = fn0)
    endif

    asiid = cdf_open(fn0)
    vars = ['time','image_size','pixel_index','minlat','midn']
    asidat = scdfread(asiid, vars, skt=skt)
    uts = *(asidat[0].value)
    imgszs = *(asidat[1].value)
    pxidxs = *(asidat[2].value)
    minlat = *(asidat[3].value) & minlat = minlat[0]
    midns = *(asidat[4].value)
    
    nrec = n_elements(uts)-1
    imgs = bytarr(nrec,imgszs[0],imgszs[1])
    tvar = 'thg_mosaic'
    ; previous image.
    img0 = bytarr(imgszs)
    img0[pxidxs] = *((scdfread(asiid,tvar,0, skt=skt, /silent))[0].value)
    for i = 1, nrec do begin
        ; current image.
        img1 = bytarr(imgszs)
        img1[pxidxs] = *((scdfread(asiid,tvar,i, skt=skt, /silent))[0].value)
        imgs[i-1,*,*] = img1-img0
        img0 = img1     ; iteration.
    endfor
    
    cdf_close, asiid
    
    return, {thg_diff_time:uts[1:nrec],thg_diff:imgs}

end

rootdir = sdiskdir('Research')
tr = ['2013-05-01/07:35','2013-05-01/07:40']
sites = ['tpas','atha']
fn = rootdir+'\sdata\themis\thg\mosaic\thg_asf_mosaic_2013_0501_0400_to_1000.cdf'

diff = sread_thg_asi_mosaic_diff(tr, sites)

nrec = n_elements(diff.thg_diff_time)
imgszs = size(reform(diff.thg_diff[0,*,*]),/dimensions)

window, 0, xsize = imgszs[0], ysize = imgszs[1]

for i = 0, nrec-1 do begin
    tv, reform(diff.thg_diff[i,*,*])
    wait, 0.1
endfor

end