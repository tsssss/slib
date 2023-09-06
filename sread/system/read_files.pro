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
pro read_files, time, files=files, request=request, errmsg=errmsg

    errmsg = ''


    foreach key, ['var_list'] do if ~request.haskey(key) then request[key] = !null

    nfile = n_elements(files)
    if nfile eq 0 then begin
        errmsg = handle_error('No file is available ...')
        return
    endif
    
    lprmsg, 'Reading variables from files ...'
    foreach file, files do begin
        if file_test(file) ne 0 then continue
        errmsg = handle_error('File does not exist: '+file+' ...')
        return
        lprmsg, '    '+file
    endforeach


    var_lists = request.var_list
    if n_elements(var_lists) eq 0 then begin
        errmsg = handle_error('No var_list ...')
        return
    endif


    foreach var_list, var_lists do begin
        if ~isa(var_list,'dictionary') then continue
        keys = ['in_vars','out_vars','time_var_name','time_var_type','generic_time']
        foreach key, keys do if ~var_list.haskey(key) then var_list[key] = !null
        in_vars = var_list.in_vars
        nvar = n_elements(in_vars)
        if nvar eq 0 then continue
        out_vars = var_list.out_vars
        if n_elements(out_vars) ne nvar then out_vars = in_vars

        lprmsg, 'New variable list ...'

    ;---Check if there is a time var.
        time_var_name = var_list.time_var_name
        has_time_var = n_elements(time_var_name) eq 1
        if has_time_var then begin
            time_var_type = var_list.time_var_type
            if n_elements(time_var_type) eq 0 then time_var_type = 'unix'
            lprmsg, 'A time_var found: '+time_var_name+', in '+time_var_type+' ...'
        endif else lprmsg, 'No time_var found ...'

    ;---Coerce to nptr_dat, dep_vars.
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


    ;---Find rec_infos using time info.
        generic_time = var_list.generic_time
        if generic_time then lprmsg, 'Dependent variable as-is, do not interpret as time ...'
        
        check_rec_info = n_elements(time) ne 0 and has_time_var
        if check_rec_info then begin
            lprmsg, 'Checking record info using the dependent variable ...'
            if ~keyword_set(generic_time) then begin
                if n_elements(time_type) eq 0 then time_type = default_time_type()
                time_info = convert_time(time, from=time_type, to=time_var_type)
                dtype = size(time_info[0],/type)
                if dtype eq 9 or dtype eq 6 then begin    ; where doesn't work properly with complex number
                    time_info = real_part(time_info)    ; can overwrite times, it will be read again later.
                endif
            endif
            if errmsg ne '' then begin
                errmsg = handle_error('Time variable :'+time_var_name+' does not exist in files ...')
                return
            endif
            
            rec_infos = list()
            foreach file, files, ii do begin
                the_times = *(read_data(file, time_var_name, errmsg=errmsg))
                dtype = size(the_times[0],/type)
                if dtype eq 9 or dtype eq 6 then begin    ; where doesn't work properly with complex number
                    the_times = real_part(the_times)    ; can overwrite times, it will be read again later.
                endif
                
                if n_elements(time_info) eq 1 then begin
                    if product(minmax(the_times)-time_info[0]) gt 0 then begin
                        rec_infos.add, !null
                    endif else begin
                        tmp = min(the_times-time_info[0], index, /absolute)
                        rec_infos.add, index
                    endelse
                endif else begin
                    index = where_pro(the_times, '[]', time_info, count=count)
                    if count eq 0 then rec_infos.add, !null else rec_infos.add, minmax(index)
                endelse
            endforeach
            
            flags = bytarr(nfile)   ; 1 for irrelevant files.
            foreach tmp, rec_infos, ii do if n_elements(tmp) eq 0 then flags[ii] = 1
            index = where(flags eq 0, count)
            if count eq 0 then begin
                errmsg = handle_error('No data found in for given time_info ...')
                return
            endif
            files = files[index]
            rec_infos = (rec_infos[index]).toarray()

            times = read_data(files, time_var_name, rec_info=rec_infos, /data, errmsg=errmsg)
            if ~keyword_set(generic_time) then times = convert_time(times, from=time_var_type, to=time_type)
        endif else begin
            rec_infos = intarr(nfile,2)-1   ; Read all data.
        endelse


    ;---Read data.
        lprmsg, 'Reading data ...'
        ptr_dats = ptrarr(ndep_var)
        var_flag = bytarr(ndep_var)
        for i=0, ndep_var-1 do begin
            ptr_dats[i] = read_data(files, dep_vars[i], rec_info=rec_infos, errmsg=errmsg)
            if errmsg ne '' then begin
                lprmsg, 'Variable: '+dep_vars[i]+' does not exist in files ...'
                var_flag[i] = 1
            endif
        endfor


    ;---Store data in memory.
        lprmsg, 'Storing data to memory ...'
        if n_elements(times) eq 0 then times = 0
        for i=0, ndep_var-1 do begin
            if var_flag[i] eq 1 then continue   ; skip vars do not exist in file.
            store_data, out_vars[i], times, temporary(*ptr_dats[i])
            ptr_free, ptr_dats[i]
        endfor
    endforeach

end
