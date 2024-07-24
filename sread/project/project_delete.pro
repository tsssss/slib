;+
; Delete project.
;-

function project_delete, project_info, root_dir=root_dir

    errmsg = ''
    retval = !null

    case strlowcase(typename(project_info)) of
        'string': project = project_init(strlowcase(project_info[0]), root_dir=root_dir, no_save=1)
        'dictionary': project = project_info
        else: errmsg = 'Invalid type of project_info ...'
    endcase

    lprmsg, 'Deleting project: '+project.id+' ...'
    del_data, project.var
    lprmsg, 'Deleting data dir '+project.data_dir+'...'
    file_delete, project.data_dir, recursive=1, allow_nonexistent=1
    lprmsg, 'Deleting plot dir '+project.plot_dir+'...'
    file_delete, project.plot_dir, recursive=1, allow_nonexistent=1
    lprmsg, 'Deleting code dir '+project.code_dir+'...'
    file_delete, project.code_dir, recursive=1, allow_nonexistent=1
    lprmsg, 'Deleting root dir '+project.root_dir+' ...'
    file_delete, project.root_dir, recursive=1, allow_nonexistent=1
    return, 1

end


proj_id = '2024_test2'
proj = project_load(proj_id)
event = project_add_event(proj, time_range=['2014-03-01','2014-03-02'])
stop
print, project_delete(proj)
end