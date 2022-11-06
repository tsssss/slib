;+
; Run for all or and at.
;-
;

pro polar_sdt_create_combo_use_cdaweb_oa, types=types

    compile_opt idl2
    on_error, 0
    
    source_root = join_path([sdiskdir('Research'),'data','polar','orbit'])
    link_root = join_path([sdiskdir('Research'),'sdata','sdt','polar','combo'])
    version = (n_elements(version) eq 0)? 'v[0-9]{2}': version
    
    version = 'v[0-9]{2}'
    type_info = []
    type_info = [type_info, $
        {id: 'or_def', $
        source_file_pattern: 'po_or_[a-z]{3}_%Y%m%d_'+version+'.cdf', $
        source_path_pattern: join_path([source_root,'def_or','%Y']), $
        link_file_pattern: '', $
        link_path_pattern: join_path([link_root,'%Y','%m'])}]
    type_info = [type_info, $
        {id: 'or_pre', $
        source_file_pattern: 'po_or_[a-z]{3}_%Y%m%d_'+version+'.cdf', $
        source_path_pattern: join_path([source_root,'pre_or','%Y']), $
        link_file_pattern: '', $
        link_path_pattern: join_path([link_root,'%Y','%m'])}]
    type_info = [type_info, $
        {id: 'at_def', $
        source_file_pattern: 'po_at_[a-z]{3}_%Y%m%d_'+version+'.cdf', $
        source_path_pattern: join_path([source_root,'def_at','%Y']), $
        link_file_pattern: '', $
        link_path_pattern: join_path([link_root,'%Y','%m'])}]
    type_info = [type_info, $
        {id: 'at_pre', $
        source_file_pattern: 'po_at_[a-z]{3}_%Y%m%d_'+version+'.cdf', $
        source_path_pattern: join_path([source_root,'pre_at','%Y']), $
        link_file_pattern: '', $
        link_path_pattern: join_path([link_root,'%Y','%m'])}]
    type_info = [type_info, $
        {id: 'spha', $
        source_file_pattern: 'po_k0_spha_%Y%m%d_'+version+'.cdf', $
        source_path_pattern: join_path([source_root,'spha_k0','%Y']), $
        link_file_pattern: '', $
        link_path_pattern: join_path([link_root,'%Y','%m'])}]
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
            source_path = apply_time_to_pattern(tinfo.source_path_pattern, tut)
            basename = apply_time_to_pattern(tinfo.source_file_pattern, tut)
            files = file_search(source_path+'/*')
            
            ; filter out the files that matches the current day.
            idx = where(stregex(files, basename) ne -1, cnt)
            ;data_avail_info[i].(j) = cnt
            flags[i] = cnt
            if cnt eq 0 then continue
            local_file = files[idx]
            
            ; check link path.
            link_path = apply_time_to_pattern(tinfo.link_path_pattern, tut)
            if file_test(link_path,/directory) eq 0 then file_mkdir, link_path

            ; generate the symbolic link.
            if tinfo.link_file_pattern ne '' then begin
                ; choose the highst level to link to.
                local_file = local_file[sort(local_file)]
                local_file = local_file[-1]
                link_file = apply_time_to_pattern(tinfo.link_file_pattern, tut)
            endif else begin
                link_file = file_basename(local_file)
            endelse

            nfile = n_elements(local_file)
            for k=0, nfile-1 do begin
                file = local_file[k]
                combo_file = join_path([link_path,link_file[k]])
                if file_test(combo_file) eq 1 then file_delete, combo_file
                cmd = 'ln -s "'+file+'" "'+combo_file+'"'
                spawn, cmd, msg, errmsg
                if msg ne '' then lprmsg, msg
                if errmsg ne '' then lprmsg, errmsg
            endfor
        endfor
        
        ; save flags to disk.
        tvar = 'po_avail_flag_'+tinfo.id
        store_data, tvar, days, flags
        tplot_save, tvar, filename=srootdir()+'/'+tvar+'.tplot'
    endfor

end

;polar_sdt_create_combo_use_cdaweb_oa, types=['spha','or_def','or_pre','at_def','at_pre']
;end