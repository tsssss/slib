;+
; Load project.
;-

function project_load, project_info, root_dir=root_dir

    errmsg = ''
    retval = !null

    case strlowcase(typename(project_info)) of
        'string': project = project_init(strlowcase(project_info[0]), no_save=1, root_dir=root_dir)
        'dictionary': project = project_info
        else: errmsg = 'Invalid type of project_info ...'
    endcase

    if errmsg eq '' then if ~project.haskey('file') then $
        errmsg = 'Invalid project dictionary ...'
    if errmsg ne '' then begin
        errmsg = handle_error(errmsg)
        return, retval
    endif
    
    if file_test(project.file) eq 0 then begin
        project = project_init(project.id, root_dir=root_dir)
    endif
    tplot_restore, filename=project.file
    project = get_var_data(project.var)
    
    ; GoogleDrive appears as different names in different OS.
    if ~file_test(project.root_dir,/directory) then begin
        project.root_dir = join_path([googledir(),'works',project.id_with_year])
        project.data_dir = join_path([project.root_dir,'data'])
        project.plot_dir = join_path([project.root_dir,'plot'])
        project.code_dir = join_path([project_idl_dir(),project.name])
        project.file = join_path([project.data_dir,project.name+'_project_info.tplot'])
    endif
    if ~file_test(project.file) then call_procedure, project.name+'_init_project', project
    if ~file_test(project.file) then message, 'Something wrong in loading the project info ...'

    return, project

end

project_info = project_load('arc')
end