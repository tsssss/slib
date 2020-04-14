;+
; Return a pointer of data. 
; 
; files. A string or a string array [n] of files.
; var0. A string for the variable to read.
; rec_info. An array of [n,2], optional. Default value is [n,2] of -1's.
;   Any range with negative value is treated as [-1,-1], meaning to read all.
;   A range with two equal numbers means to read one record.   
; no_merge. A boolean. Set it to return an array of pointer in [n]. Each
;   element points to the data in one file.
; data. A boolean. Set it to return data rather than pointer.
;-
;

function read_data, files, var0, rec_info=ranges, errmsg=errmsg, $
    no_merge=no_merge, data=data, $
    _extra=ex
    
    retval = ptr_new(!null)
    errmsg = ''
    catch, error
    if error ne 0 then begin
        errmsg = handle_error(!error_state.msg)
        catch, /cancel
        return, retval
    endif

;---Treat files.
    nfile = n_elements(files)
    if nfile eq 0 then begin
        errmsg = handle_error('No input file ...')
        return, retval
    endif
    flags = bytarr(nfile)
    for i=0, nfile-1 do flags[i] = file_test(files[i])
    index = where(flags eq 1, nfile)
    if nfile eq 0 then begin
        errmsg = handle_error('Input file does not exist ...')
        return, retval
    endif
    files = files[index]
    
    result = stregex(files[0], '\.([^.]+)$', /extract, /subexpr)
    if result[0] eq '' then begin
        errmsg = handle_error('Invalid file extension ...')
        return, retval
    endif
    extension = result[1]
    
;---Treat variable.
    if n_elements(var0) ne 1 then begin
        errmsg = handle_error('This program needs only one var as input ...')
        return, retval
    endif
    var = var0[0]
    
;---Treat range.
    ; [n] for a single record, [n,2] for a record range.
    ; For a record range, Any negative range means all record, e.g., [-1,-1].
    nrange = n_elements(ranges)
    if nrange ne nfile*2 then ranges = intarr(nfile,2)-1
    for i=0, nfile-1 do begin
        if ranges[i,0] lt 0 or ranges[i,1] lt 0 then ranges[i,*] = -1
        if ranges[i,0] gt ranges[i,1] then ranges[i,*] = ranges[i,[1,0]]
    endfor
    
;---Read data. The protocal is to have {name, value, nrec}.
    ptr_dat = ptrarr(nfile)
    for i=0, nfile-1 do begin
        rec_info = reform(ranges[i,*])
        if rec_info[0] eq rec_info[1] then rec_info = rec_info[0]
        case extension of
            'cdf': dat = scdfread(files[i], var, rec_info=rec_info, _extra=ex)
            'netcdf': dat = snetcdfread(files[i], var, rec_info=rec_info, _extra=ex)
            else: begin
                errmsg = handle_error('Does not support '+extension+' yet ...')
                return, retval
                end
        endcase
        ptr_dat[i] = dat.value
    endfor
    
    if keyword_set(no_merge) then return, ptr_dat
    dat = []
    for i=0, nfile-1 do dat = [dat,temporary(*ptr_dat[i])]
    if keyword_set(data) then return, dat
    return, ptr_new(dat)
    
end

files = '/Volumes/Research/sdata/opt_hydra/l1_data/20041228_hyd_ddcal_v12.20.cdf'

files = '/Users/Sheng/data/themis/thg/l1/asi/whit/2014/08/thg_l1_asf_whit_2014082810_v01.cdf'
in_var = 'thg_asf_whit'
range = transpose([1,3])

files = '/Users/Sheng/data/themis/thg/l1/asi/whit/2014/08/thg_l1_asf_whit_2014082810_v01.cdf'
in_var = 'thg_asf_whit'
range = transpose([1,1])


ptr_data = read_data(files, in_var, range=range, errmsg=errmsg)
help, *ptr_data
ptr_free, ptr_data
end