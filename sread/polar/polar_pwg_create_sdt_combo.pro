;+
; Map data to a combo folder for sdt to read.
;-
;
pro polar_pwg_create_sdt_combo, loc_root

    if size(loc_root,/type) ne 7 then message, 'Input directory is not a string ...'
    if file_test(loc_root, /directory) eq 0 then message, 'The input directory does not exist ...'
    combo_root = join_path([loc_root,'sdt_combo'])
    pwg_root = join_path([loc_root,'pwg'])
    if file_test(combo_root,/directory) eq 0 then file_mkdir, combo_root
    
    types = ['def_at','def_or','pre_at','pre_or','efi','mfe','spha']
    types = ['def_or','pre_at','pre_or','efi','mfe','spha']

    ; Types of data.
    version = 'v[0-9]{2}'
    type_info = []
    type_info = [type_info, $
        {id: 'def_at', $
        base_pattern: 'po_at_def_%Y%m%d_'+version+'.cdf', $
        local_pattern: join_path([pwg_root,'def','at','%Y']), $
        combo_pattern: join_path([combo_root,'%Y','%m'])}]
    type_info = [type_info, $
        {id: 'def_or', $
        base_pattern: 'po_or_def_%Y%m%d_'+version+'.cdf', $
        local_pattern: join_path([pwg_root,'def','or','%Y']), $
        combo_pattern: join_path([combo_root,'%Y','%m'])}]
    type_info = [type_info, $
        {id: 'def_pa', $
        base_pattern: 'po_pa_def_%Y%m%d_'+version+'.cdf', $
        local_pattern: join_path([pwg_root,'def','pa','%Y']), $
        combo_pattern: join_path([combo_root,'%Y','%m'])}]
    type_info = [type_info, $
        {id: 'pre_at', $
        base_pattern: 'po_at_pre_%Y%m%d_'+version+'.cdf', $
        local_pattern: join_path([pwg_root,'pre','at','%Y']), $
        combo_pattern: join_path([combo_root,'%Y','%m'])}]
    type_info = [type_info, $
        {id: 'pre_or', $
        base_pattern: 'po_or_pre_%Y%m%d_'+version+'.cdf', $
        local_pattern: join_path([pwg_root,'pre','or','%Y']), $
        combo_pattern: join_path([combo_root,'%Y','%m'])}]
    type_info = [type_info, $
        {id: 'spha', $
        base_pattern: 'po_k0_spha_%Y%m%d_'+version+'.cdf', $
        local_pattern: join_path([pwg_root,'spha','k0','%Y']), $
        combo_pattern: join_path([combo_root,'%Y','%m'])}]
    type_info = [type_info, $
        {id: 'efi', $
        base_pattern: 'po_lz_efi_%Y%m%d_'+version+'.dat', $
        local_pattern: join_path([pwg_root,'efi','lz','%Y']), $
        combo_pattern: join_path([combo_root,'%Y','%m'])}]
    type_info = [type_info, $
        {id: 'mfe', $
        base_pattern: 'po_lz_mfe_%Y%m%d_'+version+'.dat', $
        local_pattern: join_path([pwg_root,'mfe','lz','%Y']), $
        combo_pattern: join_path([combo_root,'%Y','%m'])}]
    avail_types = type_info.id

    ; check if input types are available.
    types = types[uniq(types, sort(types))]
    types = strlowcase(types)
    ntype = n_elements(types)
    foreach type, types do begin
        idx = where(avail_types eq type, cnt)
        if cnt eq 0 then message, 'Invalid type: '+type+' ...'
    endforeach


    ; mission time in days.
    utr0 = time_double(['1996-01-01','2008-12-31'])
    days = break_down_times(utr0)
    nday = n_elements(days)


    for j=0, ntype-1 do begin
        ; flag for data availability.
        flags = intarr(nday)

        idx = where(avail_types eq types[j])
        tinfo = type_info[idx]

        for i=0, nday-1 do begin
            tut = days[i]
            lprmsg, 'Processing '+time_string(tut)+' ...'

            ; check source path and file.
            basename = apply_time_to_pattern(tinfo.base_pattern, tut)
            local_path = apply_time_to_pattern(tinfo.local_pattern, tut)
            files = file_search(local_path+'/*')

            ; filter out the files that matches the current day.
            idx = where(stregex(files, basename) ne -1, cnt)
            ;data_avail_info[i].(j) = cnt
            flags[i] = cnt
            if cnt eq 0 then continue
            local_file = files[idx]

            ; check combo path.
            combo_path = apply_time_to_pattern(tinfo.combo_pattern, tut)
            if file_test(combo_path,/directory) eq 0 then file_mkdir, combo_path

            ; generate the symbolic link.
            foreach file, local_file do begin
                combo_file = join_path([combo_path,file_basename(file)])
                if file_test(combo_file) eq 1 then file_delete, combo_file
                cmd = 'ln -s "'+file+'" "'+combo_file+'"'
                spawn, cmd, msg, errmsg
                if msg ne '' then lprmsg, msg
                if errmsg ne '' then lprmsg, errmsg
            endforeach
        endfor

        ; save flags to disk.
        tvar = 'po_avail_flag_'+tinfo.id
        store_data, tvar, days, flags
        tplot_save, tvar, filename=srootdir()+'/'+tvar+'.tplot'
    endfor

end

loc_root = sdiskdir('Research')+'/sdata/polar'
polar_pwg_create_sdt_combo, loc_root
end