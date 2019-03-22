;+
; Read variables out of given files, and store them in memory.
; 
; files. A string array of [n]. Full file names that must exist on disk.
; in_vars. A string array of [n]. The variables to be read.
; out_vars. A string array of [n]. The variable names when stored in memory.
; time_info. A time or time range in utsec. Optional input to select data.
; time_type. A string by default is 'unix'. Sets the type of time_info.
; time_var_name. A string. The name of the time variable in files. Optional, but
;   once it is set, times will be returned.
; times. An array of times in utsec. Output.
; time_var_type. A string sets the type of time for the time variable. For
;   example: 'epoch', 'epoc16', etc.
; generic_time. A boolean. Set it to interpret time, time_var_name, times as
;   a generic independent variable, but not time. Once set, time_var_type has
;   no effect. But make it work, the generic independent variable should be
;   monotonically increase.
;-
;
pro read_and_store_var, files, in_vars=in_vars, errmsg=errmsg, $
    time_info=time, time_type=time_type, $
    time_var_name=time_var_name, time_var_type=time_var_type, $
    times=times, generic_time=generic_time, $
    out_vars=out_vars, ptr_out_vars=ptr_out_vars, ptr_in_vars=ptr_in_vars
    
    errmsg = ''
    
;---Check input.
    nfile = n_elements(files)
    if nfile eq 0 then begin
        errmsg = handle_error('No input file ...')
        return
    endif
    for i=0, nfile-1 do $
        if file_test(files[i]) eq 0 then begin
            errmsg = handle_error('File does not exist: '+files[i]+' ...')
            return
        endif
    

    if n_elements(in_vars) eq 0 then begin
        if n_elements(ptr_in_vars) eq 0 then begin
            errmsg = handle_error('No input variables ...')
            return
        endif else in_vars = *ptr_in_vars
    endif
    
    if n_elements(out_vars) eq 0 then begin
        if n_elements(ptr_out_vars) eq 0 then begin
            out_vars = in_vars
        endif else out_vars = *ptr_out_vars
    endif
    if n_elements(out_vars) ne n_elements(in_vars) then out_vars = in_vars

    
;---Coerce to nptr_dat, dep_vars.
    if n_elements(time_var_name) eq 0 then has_time_var = 0 else has_time_var = time_var_name[0] ne ''
    if n_elements(time_var_type) eq 0 then has_time_var = 0 else has_time_var = time_var_type[0] ne ''
    
    if ~has_time_var then begin
        nptr_dat = n_elements(in_vars)
        dep_vars = in_vars
    endif else begin
        index = where(in_vars ne time_var_name, count)
        dep_vars = in_vars[index]
        out_vars = out_vars[index]
        nptr_dat = count+1
    endelse
    ndep_var = n_elements(dep_vars)
    
    
;---Find a rec_infos using time info.
    rec_infos = intarr(nfile,2)-1
    check_rec_info = n_elements(time) ne 0 and has_time_var
    
    if check_rec_info then begin
        if ~keyword_set(generic_time) then begin
            if n_elements(time_type) eq 0 then time_type = default_time_type()
            time_info = convert_time(time, from=time_type, to=time_var_type)
        endif
        ptr_times = read_data(files, time_var_name, errmsg=errmsg, /no_merge)
        if errmsg ne '' then begin
            errmsg = handle_error('Time variable :'+time_var_name+' does not exist in files ...')
            return
        endif
        times = []
        time_ranges = dblarr(nfile,2)
        nrecs = dblarr(nfile)
        for i=0, nfile-1 do begin
            tmp = *ptr_times[i]
            times = [times,tmp]
            time_ranges[i,*] = [tmp[0],tmp[-1]]
            nrecs[i] = n_elements(tmp)
        endfor
        if n_elements(time_info) eq 1 then begin
            tmp = min(times-time_info[0], index, /absolute)
            rec_infos[*] = index
        endif else begin
            time_ranges = time_info[1]<time_ranges>time_info[0]
            for i=0, nfile-1 do begin
                dtype = size(times,/type)
                if dtype eq 9 or dtype eq 6 then begin    ; where doesn't work properly with complex number
                    times = real_part(times)    ; can overwrite times, it will be read again later.
                    time_ranges = real_part(time_ranges)
                endif
                index = lazy_where(times, time_ranges[i,*], count=count)
                
                rec_infos[i,*] = index[0]+[0,count]
                if count eq 0 then begin
                    errmsg = handle_error('No data found in for given time_info ...')
                    return
                endif
            endfor
            ; Deal with when files connect, skip the first record of the next file.
            for i=1, nfile-1 do begin
                rec_infos[i,*] -= nrecs[i-1]
                if time_ranges[i-1,1] eq time_ranges[i,0] then rec_infos[i,1] += 1
            endfor
        endelse
        times = read_data(files, time_var_name, rec_info=rec_infos, /data, errmsg=errmsg)
        if ~keyword_set(generic_time) then times = convert_time(times, from=time_var_type, to=time_type)
    endif
    
    
;---Read data.
    ptr_dats = ptrarr(ndep_var)
    for i=0, ndep_var-1 do begin
        ptr_dats[i] = read_data(files, dep_vars[i], rec_info=rec_infos, errmsg=errmsg)
        if errmsg ne '' then lprmsg, 'Variable: '+dep_vars[i]+' does not exist in files ...'
    endfor


;---Store data in memory.    
    if n_elements(times) eq 0 then times = 0
    for i=0, ndep_var-1 do begin
        store_data, out_vars[i], times, temporary(*ptr_dats[i])
        ptr_free, ptr_dats[i]
    endfor
    
end
