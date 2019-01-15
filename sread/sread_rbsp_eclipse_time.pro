;+
; process <remote rbsp>/MOC_data_products/RBSPX/eclipse_predict/rbspx_yyyy_doy_??.pecl
; save the results in <local rbsp>/rbspx/efw/MOC_data_product/eclipse_predict/data/rbspx_eclipse_yyyy.sav.
; return {uts:uts, flags:flags}
; 
;-

function sread_rbsp_eclipse_time, tr0, probes = probe0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type, version = version
    
    compile_opt idl2

    utr0 = tr0
    if size(utr0,/type) eq 7 then utr0 = time_double(utr0)

    ; local and remote directory.
    sep = path_sep()
    if n_elements(locroot) eq 0 then locroot = sdiskdir('Research')+'/sdata/rbsp'
    if n_elements(remroot) eq 0 then $
        remroot = 'http://rbsp.space.umn.edu/data/rbsp'

    ; **** prepare file names.
    type = 'MOC_data_products'
    prb = (n_elements(probe0))? probe0: 'a'
    vsn = (n_elements(version))? version: 'v01'
    ext = 'sav'
    rbspx = 'rbsp'+prb
    
    locpath = locroot+'/'+rbspx+'/eclipse_predict/data'
    baseptn = rbspx+'_eclipse_time_YYYY'+'.'+ext
    rbsp_gen_eclipse_times, prb, tr0

    ; prepare locfns, nfn.
    sprepfile0, utr0, ptn = baseptn, locfns = locfns, locroot = locpath

    nfn = n_elements(locfns)
    for i = 0, nfn-1 do begin
        tlocpath = file_dirname(locfns[i])
        locfns[i] = sgetfile(file_basename(locfns[i]), tlocpath)
    endfor
    idx = where(locfns ne '', nfn)
    if nfn ne 0 then locfns = locfns[idx] else return, -1
    
    tuts = []
    tflags = []
    for i = 0, nfn-1 do begin
        restore, filename = locfns[i]
        ; idx = where(uts ge utr0[0] and uts le utr0[1])
        if n_elements(utr0) eq 1 then begin
            tmp = min(uts-utr0, idx, /absolute)
        endif else begin
            idx = where(uts ge utr0[0] and uts le utr0[1])
        endelse
        tuts = [tuts,uts[idx]]
        tflags = [tflags,flags[idx]]
    endfor

    if n_elements(tuts) eq 1 then begin
        tuts = tuts[0]
        tflags = tflags[0]
    endif
    
    return, {uts:tuts,flags:tflags}
    
end

utr = time_double('2013-03-05')
utr = time_double(['2012-09-25','2012-09-26'])
tmp = sread_rbsp_eclipse_time(utr, probes = 'b')
end
