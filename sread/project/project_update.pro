
function project_update, project
    store_data, project.var, 0, project
    tplot_save, project.var, filename=project.file
    return, 1
end