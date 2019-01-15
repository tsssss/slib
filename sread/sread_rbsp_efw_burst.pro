;+
; Type: function.
; Purpose: read RBSP EFW burst data.
; Parameters: <+++>.
;   <+varname+>, <+in/out+>, <+datatype+>, <+req/opt+>. <+++>.
; Keywords: <+++>.
;   <+varname+>, <+in/out+>, <+datatype+>, <+req/opt+>. <+++>.
; Return: <+++>.
; Notes: Only allow for loading one file.
; Dependence: <+++>.
; History:
;   2016-06-10, Sheng Tian, create.
;-

function sread_rbsp_efw_burst, tr0, probes = probe0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    locroot = locroot, remroot = remroot, type = type, version = version

    compile_opt idl2
    
    ; local and remote directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('rbsp')
    if n_elements(remroot) eq 0 then $
;        remroot = 'http://themis.ssl.berkeley.edu/data/rbsp'
        remroot = 'http://rbsp.space.umn.edu/data/rbsp'

    ; **** prepare file names.
    type = (n_elements(type))? type: 'vb1'
    prb = (n_elements(probe0))? probe0: 'a'
    vsn = (n_elements(version))? version: 'v[0-9.]{2}'
    ext = 'cdf'
    
    baseptn = 'rbsp'+prb+'_l1_'+type+'_YYYYMMDD_'+vsn+'.'+ext
    rempaths = [remroot,'rbsp'+prb,'l1',type,'YYYY',baseptn]
    locpaths = [locroot,'rbsp'+prb,'efw/l1',type,'YYYY',baseptn]

    ; prepare locfns, nfn.
    remfns = sprepfile(tr0, paths = rempaths)
    locfns = sprepfile(tr0, paths = locpaths)
    nfn = n_elements(locfns)
    
    for i = 0, nfn-1 do begin
        tlocpath = file_dirname(locfns[i])
        trempath = file_dirname(remfns[i])
        locfns[i] = sgetfile(file_basename(locfns[i]), tlocpath, trempath)
    endfor
    idx = where(locfns ne '', nfn)
    if nfn ne 0 then locfns = locfns[idx] else return, -1

    ; **** prepare var names.
    if n_elements(var0s) eq 0 then begin
        case type of
            'vb1': var0s = ['epoch','vb1']
            'mscb1': var0s = ['epoch','mscb1']
        endcase
    endif
    if n_elements(var1s) eq 0 then var1s = idl_validname(var0s)
    var1s = idl_validname(var1s)


    ; **** module for variable loading.
    nvar = n_elements(var0s)
    if nvar ne n_elements(var1s) then message, 'mismatch var names ...'
    ptrs = ptrarr(nvar,/allocate_heap)

    epvar = 'epoch'
    ; read data only within the wanted time.
    cdfid = cdf_open(locfns[0])
    cdf_control, cdfid, variable = epvar, get_var_info = vinfo, /zvariable
    nrec = vinfo.maxrec+1
    cdf_varget, cdfid, epvar, et16, rec_start = 0, rec_count = nrec
    et16 = transpose(et16)
    ; convert epoch16 to ut sec.
    uts = real_part(et16)+imaginary(et16)*1d-12 - 62167219200D
    et16 = 0    ; free memory.
    case n_elements(tr0) of
        2: utr = time_double(tr0)
        1: utr = time_double(tr0)+[0d,86400]
        0: utr = minmax(uts)
    endcase
    idx = where(uts ge utr[0] and uts le utr[1], nrec)
    if nrec eq 0 then begin
        cdf_close, cdfid
        return, -1
    endif
    rec0 = idx[0]
    
    ; read variables.
    for j = 0, nvar-1 do begin
        cdf_varget, cdfid, var0s[j], dat, rec_start = rec0, rec_count = nrec
        dat = transpose(dat)
        *ptrs[j] = dat
    endfor
    cdf_close, cdfid

    ; move data to structure.
    dat = create_struct(var1s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var1s[j],*ptrs[j])
    for j = 0, nvar-1 do ptr_free, ptrs[j]

    return, dat

end

utr = time_double('2013-06-07/04:52'+[':57.00',':58.50'])
efwb1 = sread_rbsp_efw_burst(utr, probes = 'a', type = 'mscb1')

end
