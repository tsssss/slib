;+
; Read Weygand's current data.
;-


function themis_read_weygand_parse_eics, file, glat, glon
    ; Horizontal current:
    ;   Jx (mA/m, points to geographic north),
    ;   Jy (mA/m, points to geographic east)

    nline = file_lines(file)
    if nline eq 0 then return, !null
    if nline ne 183 then return, !null
    ncol = 4
    data = fltarr(ncol, nline)
    openr, lun, file, /get_lun
    readf, lun, data
    free_lun, lun

    glat = reform(data[0,*])
    glon = reform(data[1,*])
    return, transpose(data[2:3,*])

end

function themis_read_weygand_parse_secs, file, glat, glon
    ; Vertical current: J (A, points to vertical up)

    nline = file_lines(file)
    if nline eq 0 then return, !null
    ncol = 3
    data = fltarr(ncol, nline)
    openr, lun, file, /get_lun
    readf, lun, data
    free_lun, lun

    glat = reform(data[0,*])
    glon = reform(data[1,*])
    return, transpose(data[2,*])

end


pro themis_read_weygand_gen_file, file_time, filename=local_file, remote_root=remote_root, errmsg=errmsg

    if file_test(local_file) ne 0 then file_delete, local_file
    cdf_touch, local_file
    
    local_path = fgetpath(local_file)
    foreach the_type, ['EICS','SECS'] do begin
        base_name = apply_time_to_pattern(the_type+'%Y%m%d', file_time)
        zip_name = base_name+'.zip'
        zip_file = join_path([local_path,zip_name])
        remote_file = apply_time_to_pattern(join_path([remote_root,the_type,'%Y','%m',zip_name]), file_time)
        download_file, zip_file, remote_file, errmsg=errmsg
        if errmsg ne '' then begin
            if file_test(zip_file) eq 1 then file_delete, zip_file
            return
        endif
        
        file_unzip, zip_file, files=orig_files
        index = where(stregex(orig_files, '\.dat') ne -1, nfile, complement=index2)
        if nfile eq 0 then begin
            errmsg = 'No data ...'
            return
        endif
        zip_dir = orig_files[index2]
        files = orig_files[index]
        times = time_double(strmid(fgetbase(files),4,15),tformat='YYYYMMDD_hhmmss') ; some files are duplicated.
        index = uniq(times,sort(times))
        files = files[index]
        times = times[index]

        time_var = 'ut'
        if ~cdf_has_var(time_var, filename=local_file) then begin
            cdf_save_var, time_var, value=times, filename=local_file
            cdf_save_setting, varname=time_var, filename=local_file, dictionary($
                'unit', 'sec', $
                'var_type', 'support_data' )
        endif

        case the_type of
            'EICS': suffix = '_j_hor'
            'SECS': suffix = '_j_ver'
        endcase

        routine = 'themis_read_weygand_parse_'+the_type
        tmp = call_function(routine, files[0], glat, glon)
        glat_var = 'thg_glat'+suffix
        cdf_save_var, glat_var, filename=local_file, value=glat
        glon_var = 'thg_glon'+suffix
        cdf_save_var, glon_var, filename=local_file, value=glon


        data = fltarr([nfile,size(tmp,/dimensions)])
        ndata = n_elements(data[0,*,*])
        foreach file, files, ii do begin
            tmp = call_function(routine, file)
            ;if n_elements(tmp) eq 0 then continue
            if n_elements(tmp) ne ndata then continue
            data[ii,*,*] = tmp
        endforeach
        case the_type of
            'EICS': begin
                var_name = 'thg'+suffix
                settings = dictionary($
                    'display_type', 'vector', $
                    'unit', 'mA/m', $
                    'short_name', 'J', $
                    'coord', '', $
                    'coord_labels', ['x','y'], $
                    'colors', sgcolor(['red','blue']) )
                end
            'SECS': begin
                var_name = 'thg'+suffix
                settings = dictionary($
                    'display_type', 'scalar', $
                    'unit', 'A', $
                    'short_name', 'J' )
                end
        endcase
        settings['depend_0'] = time_var
        settings['depend_1'] = glat_var
        settings['depend_2'] = glon_var

        cdf_save_var, var_name, value=data, filename=local_file
        cdf_save_setting, varname=var_name, filename=local_file, settings


        ; Clean up.
        nfile = n_elements(orig_files)
        flags = bytarr(nfile)
        for ii=0, nfile-1 do flags[ii] = file_test(orig_files[ii], directory=1)
        index = where(flags eq 0, complement=index2)
        file_delete, orig_files[index], allow_nonexistent=1
        file_delete, orig_files[index2], allow_nonexistent=1
        file_delete, zip_file, allow_nonexistent=1
        file_delete, zip_dir, allow_nonexistent=1
    endforeach

end


function themis_load_weygand_j, input_time_range, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request


    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    sync_threshold = 0

    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'themis'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/aaa_special-purpose-datasets/spherical-elementary-and-equivalent-ionospheric-currents-weygand'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse

;---Init settings.
    probe = 'g'
    thx = 'th'+probe
    valid_range = ['2007-01-19']    ; the start date applies to tha-the.
    base_name = 'thg_weygand_'+'%Y_%m%d.cdf'
    local_path = [local_root,thx,'weygand','%Y']

    request = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )
    if keyword_set(return_request) then return, request

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            themis_read_weygand_gen_file, file_time, filename=local_file, remote_root=remote_root
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    endif

    if n_elements(files) eq 0 then return, '' else return, files

end



time_range = time_double(['2007-12-12/10:05','2007-12-12/10:20']) ; data gap.
files = themis_load_weygand_j(time_range)
end