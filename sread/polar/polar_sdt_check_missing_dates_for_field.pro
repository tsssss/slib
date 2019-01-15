;+
; ftp://pwgdata.gsfc.nasa.gov/pub/compressed/po
;-
;

pro polar_sdt_check_missing_dates_for_field, loc_root, types=types
    
    compile_opt idl2
    on_error, 0
    
    if size(loc_root,/type) ne 7 then message, 'Input directory is not a string ...'
    if file_test(loc_root, /directory) eq 0 then message, 'The input directory does not exist ...'
    combo = 'combo'
    combo_root = join_path([loc_root,combo])
    if file_test(combo_root,/directory) eq 0 then file_mkdir, combo_root
    rem_root = 'ftp://pwgdata.gsfc.nasa.gov/pub/compressed/po'

    ; Types of data.
    version = 'v[0-9]{2}'
    type_info = []
    ; electric field.
    type_info = [type_info, $
        {id: 'efi', $
        base_pattern: 'po_lz_efi_%Y%m%d_'+version+'.dat', $
        local_pattern: join_path([loc_root,'lz','efi']), $
        remote_pattern: join_path([rem_root,'efi','lz','%Y']), $
        combo_pattern: join_path([loc_root,combo,'%Y','%m'])}]
    ; magnetic field.
    type_info = [type_info, $
        {id: 'mfe', $
        base_pattern: 'po_lz_mfe_%Y%m%d_'+version+'.dat', $
        local_pattern: join_path([loc_root,'lz','mfe']), $
        remote_pattern: join_path([rem_root,'mfe','lz','%Y']), $
        combo_pattern: join_path([loc_root,combo,'%Y','%m'])}]
    avail_types = type_info.id
    
    ; check if input types are available.
    types = types[uniq(types, sort(types))]
    types = strlowcase(types)
    ntype = n_elements(types)
    foreach type, types do begin
        idx = where(avail_types eq type, cnt)
        if cnt eq 0 then message, 'Invalid type: '+type+' ...'
    endforeach
    
    
    ; load flags to disk.
    index_file = 'remote-index.html'
    foreach type, types do begin
        tvar = 'po_avail_flag_'+type
        tplot_restore, filename=srootdir()+'/'+tvar+'.tplot'
        get_data, tvar, ut0s, flag0s
        
        utr0 = time_double(['1996-02-28','2008-04-28'])
        idx = where(ut0s ge utr0[0] and ut0s le utr0[1])
        days = ut0s[idx]
        flags = flag0s[idx]
        
        ; pick the info for the current type.
        idx = where(avail_types eq type)
        tinfo = type_info[idx]
        
        ; find days of missing data.
        idx = where(flags eq 0, nday)
        days = days[idx]
        for i=0, nday-1 do begin
            tut = days[i]
            lprmsg, 'Processing '+time_string(tut)+' ...'
            
            ; check remote file.
            rem_path = apply_time_to_pattern(tinfo.remote_pattern, tut)
            loc_base = apply_time_to_pattern(tinfo.base_pattern, tut)
            loc_path = apply_time_to_pattern(tinfo.local_pattern, tut)
            rem_base = loc_base+'.gz'
            
            ; check if remote file exists.
            update_index_file, index_file, loc_path, rem_path, times=tut
            loc_base = lookup_index_file(rem_base, loc_path, index_file)
            if loc_base[0] eq '' then begin
                lprmsg, 'remote file does not exist ...'
                continue
            endif
            file_delete, join_path([loc_path,index_file])
            
            ; download remote file if it exists.
            update_data_file, loc_base, loc_path, rem_path
            ;idx = where(ut0s eq tut)
            ;flag0s[idx[0]] = 1
            
            ; extract.
            zip_file = join_path([loc_path,loc_base])
            file = strmid(zip_file, 0, strpos(zip_file,'.gz'))
            if file_test(file) eq 1 then file_delete, file
            cmd = 'gunzip '+zip_file
            spawn, cmd, msg, errmsg
            if msg ne '' then lprmsg, msg
            if errmsg ne '' then lprmsg, errmsg
            
            ; check combo path.
            combo_path = apply_time_to_pattern(tinfo.combo_pattern, tut)
            if file_test(combo_path,/directory) eq 0 then file_mkdir, combo_path
            
            ; generate the symbolic link.
            combo_file = join_path([combo_path,file_basename(file)])
            if file_test(combo_file) eq 1 then file_delete, combo_file
            cmd = 'ln -s "'+file+'" "'+combo_file+'"'
            spawn, cmd, msg, errmsg
            if msg ne '' then lprmsg, msg
            if errmsg ne '' then lprmsg, errmsg
        endfor
    endforeach
    
;    tvar = 'po_avail_flag_'+type
;    store_data, tvar, ut0s, flag0s
;    tplot_restore, filename=srootdir()+'/'+tvar+'.tplot'

end


sdt_root = join_path([sdiskdir('Research'),'sdata','sdt','polar'])
polar_sdt_check_missing_dates_for_field, sdt_root, types = ['efi','mfe']
end