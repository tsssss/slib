;+
; Create a project.
; adopted from init_project.
;-

function project_init, proj_id, errmsg=errmsg, root_dir=root_dir, no_save=no_save

    project = dictionary($
        'id', proj_id )
    
    if n_elements(root_dir) eq 0 then root_dir = join_path([googledir(),'works',project.id])
    project['root_dir'] = root_dir
    project['data_dir'] = join_path([project.root_dir,'data'])
    project['plot_dir'] = join_path([project.root_dir,'plot'])
    project['code_dir'] = join_path([homedir(),'Projects','idl','spacephys','projects',project.id])
    project['var'] = project.id
    project['file'] = join_path([project.data_dir,project.id+'_project_info.tplot'])
    project['events'] = orderedhash()

    if keyword_set(no_save) then return, project

    lprmsg, 'Initializing project: '+project.id+' ...'
    lprmsg, 'Check root directory ...'
    if file_test(project.root_dir,/directory) eq 0 then begin
        lprmsg, 'Creating root directory ...'
        file_mkdir, project.root_dir
        if file_test(project.root_dir,/directory) eq 0 then begin
            msg = handle_error('Fail to create root directory ...')
            lprmsg, msg
            return, retval
        endif else lprmsg, 'Root directory created ...'
    endif else lprmsg, 'Root directory exists ...'
    if file_test(project.data_dir,/directory) eq 0 then begin
        lprmsg, 'Creating data directory ...'
        file_mkdir, project.data_dir
    endif else lprmsg, 'Data directory exists ...'
    if file_test(project.plot_dir,/directory) eq 0 then begin
        lprmsg, 'Creating plot directory ...'
        file_mkdir, project.plot_dir
    endif else lprmsg, 'Plot directory exists ...'
    if file_test(project.code_dir,/directory) eq 0 then begin
        lprmsg, 'Creating code directory ...'
        file_mkdir, project.code_dir
    endif else lprmsg, 'Code directory exists ...'

    update_project, project

    lprmsg, 'The project dictionary is saved to file ...'
    return, project

end