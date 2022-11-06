
function fgetmtime, file

    if file_test(file) eq 0 then return, !null
    finfo = file_info(file)
    return, double(finfo.mtime)

end
