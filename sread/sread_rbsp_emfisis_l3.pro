;+
; Type: function.
; Purpose: Read RBSP EMFISIS L3 data.
; Parameters:
;   <+varname+>, <+in/out+>, <+datatype+>, <+req/opt+>. <+++>.
; Keywords:
;   type, in, string, opt. Can be hires, 4sec, 1sec. Default is 4sec.
;   coord, in, string, opt. Can be gei,geo,gse,gsm,sm. Default is gsm.
; Return: <+++>.
; Notes: <+++>.
; Dependence: <+++>.
; History:
;   2016-10-11, Sheng Tian, create.
;-

function sread_rbsp_emfisis_l3, tr0, probes = probe0, filename = fn0, $
    vars = var0s, newnames = var1s, coord = coord0, $
    locroot = locroot, remroot = remroot, type = type0, version = version

    compile_opt idl2
    
    ; local and remote directory.
    sep = path_sep()
    if n_elements(locroot) eq 0 then locroot = spreproot('rbsp')
    if n_elements(remroot) eq 0 then $
        remroot = 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
    

    ; **** prepare file names.
    type = (n_elements(type0))? type0: '4sec'
    coord = (n_elements(coord0))? coord0: 'gsm'
    prb = (n_elements(probe0))? probe0: 'a'
    vsn = (n_elements(version))? version: 'v[0-9.]{5}'
    ext = 'cdf'

    ; type1 in filename, type2 in path.
    case type of
        'hires': begin
            type1 = 'hires'
            type2 = 'hires'
            end
        else: begin
            type1 = type
            type2 = type
            end
    endcase

    baseptn = 'rbsp-'+prb+'_magnetometer_'+type2+'-'+coord+'_emfisis-l3_YYYYMMDD_'+vsn+'.'+ext
    rempaths = [remroot,'rbsp'+prb,'l3/emfisis/magnetometer',type1,coord,'YYYY',baseptn]
    locpaths = [locroot,'rbsp'+prb,'emfisis/l3',type1,coord,'YYYY',baseptn]

    remfns = sprepfile(tr0, paths = rempaths)
    locfns = sprepfile(tr0, paths = locpaths)
    nfn = n_elements(locfns)
    for i = 0, nfn-1 do begin
        basefn = file_basename(locfns[i])
        locpath = file_dirname(locfns[i])
        rempath = file_dirname(remfns[i])
        locfns[i] = sgetfile(basefn, locpath, rempath, remidx = 'SHA1SUM')
    endfor
    idx = where(locfns ne '', nfn)
    if nfn ne 0 then locfns = locfns[idx] else return, -1


    ; **** prepare var names.
    if n_elements(var0s) eq 0 then begin
        case type of
            'hires': begin
                var0s = ['Epoch','Mag']
                var1s = idl_validname(var0s)
                end
            '4sec': begin
                var0s = ['Epoch','Mag']
                var1s = idl_validname(var0s)
                end
            else: message, 'have not treat type '+type+' yet ...'
        endcase
    endif
    if n_elements(var1s) eq 0 then var1s = idl_validname(var0s)
    var1s = idl_validname(var1s)


    ; **** module for variable loading.
    nvar = n_elements(var0s)
    if nvar ne n_elements(var1s) then message, 'mismatch var names ...'
    ptrs = ptrarr(nvar)
    ; first file.
    tmp = scdfread(locfns[0],var0s)
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
    
    ; trim to time, change time to normal epoch.
    epvar = 'Epoch'
    if size(tr0,/type) eq 7 then tformat = '' else tformat = 'unix'
    eps = stoepoch(tr0,tformat)
    idx = (where(var1s eq epvar, cnt))[0]
    if cnt ne 0 then begin
        tmp = stoepoch(*(ptrs[idx]), 'tt2000')
        *(ptrs[idx]) = tmp
        idx = where(tmp ge min(eps) and tmp le max(eps))
        for i = 0, nvar-1 do *ptrs[i] = (*ptrs[i])[idx,*,*,*,*,*,*,*]
    endif

    ; move data to structure.
    dat = create_struct(var1s[0],*ptrs[0])
    for j = 1, nvar-1 do dat = create_struct(dat, var1s[j],*ptrs[j])
    for j = 0, nvar-1 do ptr_free, ptrs[j]

    return, dat

end

utr = time_string(['2013-05-19'])
emfisis = sread_rbsp_emfisis_l3(utr, type = 'hires', coord = 'gse')
end
