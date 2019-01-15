;+
; use usher, guard, ibias values to determin sdt times.
;-

function sread_rbsp_efw_sdt_time, tr0, probes = probe0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type, version = version


    utr0 = time_double(tr0[0]) & utr0 = utr0-(utr0 mod 86400)+[0,86400]
    uts = smkarthm(utr0[0], utr0[1], 60, 'dx')
    nrec = n_elements(uts)
    flags = bytarr(nrec)
    padt0 = 60*5    ; sec.
    
    
    ; local and remote directory.
    sep = path_sep()
    if n_elements(locroot) eq 0 then locroot = spreproot('rbsp')
    if n_elements(remroot) eq 0 then $
;        remroot = 'http://rbsp.space.umn.edu/data/rbsp'
        remroot = 'http://themis.ssl.berkeley.edu/data/rbsp'

    ; **** prepare file names.
    type = 'hsk_beb_analog'
    prb = (n_elements(probe0))? probe0: 'a'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'
    rbspx = 'rbsp'+prb
    
    baseptn = rbspx+'_l1_'+type+'_YYYYMMDD_'+vsn+'.'+ext
    rempaths = [remroot,rbspx,'l1',type,'YYYY',baseptn]
    locpaths = [locroot,rbspx,'efw','l1',type,'YYYY',baseptn]

    ; prepare locfns, nfn.
    remfns = sprepfile(tr0, paths = rempaths)
    locfns = sprepfile(tr0, paths = locpaths)
    nfn = n_elements(locfns)
    for i = 0, nfn-1 do begin
        basefn = file_basename(locfns[i])
        locpath = file_dirname(locfns[i])
        rempath = file_dirname(remfns[i])
        locfns[i] = sgetfile(basefn, locpath, rempath)
    endfor
    idx = where(locfns ne '', nfn)
    if nfn ne 0 then locfns = locfns[idx] else return, {uts:uts,flags:flags}

    ; **** prepare var names.
    if n_elements(var0s) eq 0 then begin
        sufs = ['1','2','3','4','5','6']
        var0s = ['hdr_epoch','IEFI_GUARD'+sufs,'IEFI_USHER'+sufs]
        var1s = ['epoch','guard'+sufs,'usher'+sufs]
    endif
    if n_elements(var1s) eq 0 then var1s = idl_validname(var0s)
    var1s = idl_validname(var1s)

    ; **** module for variable loading.
    nvar = n_elements(var0s)
    if nvar ne n_elements(var1s) then message, 'mismatch var names ...'
    ptrs = ptrarr(nvar)
    ; first file.
    tmp = scdfread(locfns[0],var0s)
    if n_elements(tmp) lt n_elements(var0s) then return, {uts:uts,flags:flags}
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
    
    ; move data to structure.
    dat = create_struct(var1s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var1s[j],*ptrs[j])
    for j = 0, nvar-1 do ptr_free, ptrs[j]
    
    
    
    ; **** check sdt time.
    tuts = sfmepoch(dat.epoch,'unix')
    tnrec = n_elements(tuts)
    if tnrec le 1 then return, {uts:uts,flags:flags}

    vars = strlowcase(['guard'+sufs])
    vnames = strlowcase(tag_names(dat))
    dval0 = 5*0.5   ; dV = 5, let's say 50% change is significant.
    
    foreach tvar, vars do begin
        idx = where(vnames eq tvar)
        tdat = dat.(idx)
        tdat = round(tdat/5)*5
        vals = tdat[uniq(tdat,sort(tdat))]
        nval = n_elements(vals)
        if nval le 2 then continue  ; mode change.
        if nval ne 5 then continue  ; irregular change.
        
;        store_data, 'tmp', tuts, tdat
        idx = where(tdat eq min(vals), cnt) & i1 = idx[0]
        idx = where(tdat eq max(vals), cnt) & i2 = idx[cnt-1]
        tval = mean(vals)
        tmp = abs(tdat[i1:i2]-tval)
        idx = where(tmp eq min(tmp), cnt)+i1
        tut = mean(tuts[idx[[0,cnt-1]]])
        dt = nval*padt0*0.5
        t1 = tut-dt
        t2 = tut+dt
;        tplot, 'tmp', trange = [t1,t2]
        idx = where(uts ge t1 and uts le t2, cnt)
        if cnt ne 0 then flags[idx] = 1
    endforeach

    return, {uts:uts,flags:flags}
end

utr0 = time_double(['2012-09-25','2016-12-31'])
uts = smkarthm(utr0[0], utr0[1], 86400, 'dx')
foreach tut, uts do begin
    tmp = sread_rbsp_efw_sdt_time(tut, probes = 'a')
    tmp = sread_rbsp_efw_sdt_time(tut, probes = 'b')
endforeach
end
