;+
; Create a project.
; adopted from init_project.
;-

function project_init, project_id, errmsg=errmsg, root_dir=root_dir, no_save=no_save, year_str=year_str

    errmsg = ''
    retval = !null

    if n_elements(year_str) eq 0 then year_str = time_string(systime(1,second=1),tformat='YYYY')
    project_id_with_year = year_str+'_'+project_id

    project = dictionary($
        'id', project_id,$
        'id_with_year', project_id_with_year )
    
    if n_elements(root_dir) eq 0 then root_dir = join_path([googledir(),'works',project_id_with_year])
    project['root_dir'] = root_dir
    project['data_dir'] = join_path([project.root_dir,'data'])
    project['plot_dir'] = join_path([project.root_dir,'plot'])
    project['code_dir'] = join_path([project_idl_dir(),project.id])
    project['var'] = project.id
    project['file'] = join_path([project.data_dir,project.id+'_project_info.tplot'])
    project['events'] = orderedhash()

    if keyword_set(no_save) then return, project

    tab = '    '
    lprmsg, 'Initializing project: '+project.id+' ...'
    foreach key, ['root','data','plot','code']+'_dir' do begin
        dir = project[key]
        lprmsg, 'Checking '+key+': '+dir+' ...'
        if file_test(dir,directory=1) eq 0 then begin
            lprmsg, tab+'Creating ...'
            file_mkdir, dir
            if file_test(dir,directory=1) eq 0 then begin
                msg = handle_error('Fail to create ...')
                lprmsg, msg
                return, retval
            endif else lprmsg, tab+'Created ...'
        endif else begin
            lprmsg, tab+'Exists ...'
        endelse
    endforeach
    

    project = project_update(project)

    lprmsg, 'The project dictionary is saved to file ...'
    return, project

end