function hdf_read_var, var, filename=files, errmsg=errmsg

    errmsg = ''
    retval = !null

    data = []
    foreach file, files do data = [data,h5_getdata(file, var)]
    
    return, data

end

file = '/Volumes/data/dmsp/madrigal/dmspf18/2013/dms_20130502_18s1.001.hdf5'
;hdf2tplot, file
vars = hdf_read_var('/Data/Table Layout', filename=file)
end