;+
; Type: function.
; Purpose: Read data in given netcdf file.
; Parameters:
;   nc0, in, string/long, req. Full file name or ncid.
;   vnames, in, strarr, opt. Omit to load all vars.
;   recs, in, int/intarr[2], opt. Omit to locate all records for each var.
;       If it is int then it is the record we load, if intarr[2] it is the
;       record range. To load all records, [-1,-1] works too. Negative record
;       is treated as counting from tail, e.g., [2,-2] means [2,nrec-2], -1
;       means to load the last record.
; Keywords:
;   drec, in, int, opt. Record interval to down sample data.
;   skt, in/out, struct, opt. Set to avoid loading it every time.
;   silent, in, boolean, opt. Set to suppress printing messages.
; Return: struct. (Quantities in paranthesis may not be presented.)
;     
;     return = {
;       __name: 'cdf'
;       header: struct
;       att: struct/gatt
;       var: struct_array }
;     
;     header = {
;       __name: 'cdf.header'
;       filename: string
;       cdfformat: string
;       copyright: string
;       decoding: string
;       encoding: string
;       majority: string
;       version: string }
;       
;     gatt = {
;       natts: long
;       attname1: value1
;       attname2: value2
;         ...
;       attnameN: valueN }
;     
;     var = {
;       nvar: long
;       varname1: struct/var1
;       varname2: struct/var2
;         ...
;       varnameN: struct/varN }
;     
;     varN = {
;       name: string
;       value: array of certain type
;       nrecs: long
;       dims: longarr
;       att: struct/att }
; Notes: The data of arrays is in [n, d1, d2, ..., dm], where n is number of 
;   records, [d1, d2, ..., dm] is the dimension of data at each record. For 
;   example, an array of epoch will be in [n]; an array of electric field will 
;   be in [n,3]; an array of aurora image will be in [n,256,256].
; Dependence: slib.
; History:
;   2019-01-01, Sheng Tian, create.
;-
function snetcdfread, nc0, vnames, recs0, drec = drec, skt = skt, silent = silent
    
    compile_opt idl2
    on_error, 0
    quiet0 = !quiet
    !quiet = 1
    
    if n_elements(drec) eq 0 then drec = 1

    ; get netcdf id.
    if size(nc0, /type) eq 7 then begin
        if ~file_test(nc0) then $
            message, 'file ' + nc0 + ' does not exist ...'
        ncid = ncdf_open(nc0)
    endif else ncid = nc0

    ; read skeleton.
    if n_elements(skt) eq 0 then snetcdfskt, nc0, skt


    ; original variable names.
    novar = n_tags(skt.vars)
    ovnames = strarr(novar)
    for i = 0, novar-1 do ovnames[i] = skt.vars.(i).name

    ; claimed variable names.
    vnames = (n_elements(vnames) ne 0)? vnames: ovnames
    nvar = n_elements(vnames)
    case n_elements(recs0) of
        0: recs = lonarr(nvar,2)-1
        1: recs = [[replicate(recs0,nvar)],[replicate(recs0,nvar)]]
        2: recs = [[replicate(recs0[0],nvar)],[replicate(recs0[1],nvar)]]
    endcase
    
    
    ; read vars.
    vars = []
    if ~keyword_set(silent) then print, 'reading '+skt.name+' ...'
    for i = 0, nvar-1 do begin
        idx = where(strtrim(ovnames,2) eq vnames[i], cnt)
        if cnt eq 0 then continue
        vinfo = skt.vars.(idx)
        if ~keyword_set(silent) then print, 'reading '+vinfo.name+' ...'
        ; read data.
        varid = ncdf_varid(ncid, vinfo.name)
        ncdf_varget, ncid, varid, value
        dims = size(value, /dimensions)
        tvar = {name: vinfo.name, value: ptr_new(value), nrec:long64(dims[0])}
        vars = [vars, tvar]
    endfor
    
    ; free ncid.
    if size(nc0, /type) eq 7 then ncdf_close, ncid
    
    !quiet = quiet0

    return, vars
end



fn = '/Users/Sheng/data/goes/new_full/2014/08/goes15/netcdf/g15_magneto_512ms_20140828_20140828.nc'
dat = snetcdfread(fn)
end