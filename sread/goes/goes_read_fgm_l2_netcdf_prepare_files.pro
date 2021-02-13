;+
; Prepare netCDF files to read orbit and B field.
;-

function goes_read_fgm_l2_netcdf_prepare_files, time, probe=probe, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 2
    errmsg = ''
    retval = !null

;---Check inputs.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','goes'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/goes'
    if n_elements(version) eq 0 then version = 'v.*'


    the_probe = (strmid(probe,0,1) eq 'g')? strmid(probe,1): probe
    the_probe = string(fix(the_probe),format='(I02)')
    gxx = 'g'+the_probe
    goesxx = 'goes'+the_probe
    base_name = 'dn_magn-l2-hires_'+gxx+'_d%Y%m%d_'+version+'.nc'
    local_path = [local_root,goesxx,'fgm','l2','%Y']
    remote_path = [remote_root,goesxx,'mag_l2_netcdf','%Y']

    case gxx of
        'g10': valid_range = ['1997-05-06','2005-06-01']
        'g11': valid_range = ['2000-05-16','2010-04-14']
        'g12': valid_range = ['2001-08-31','2009-09-17']
        'g13': valid_range = ['2010-05-04','2017-12-10']
        'g14': valid_range = ['2012-10-01','2017-12-08']
        'g15': valid_range = ['2011-01-01','2017-12-10']
        'g16': valid_range = ['2018-08-29']
        'g17': valid_range = ['2018-08-01']
        else: begin
            errmsg = handle_error('Do not support '+gxx+' ...')
            return, retval
        end
    endcase

    request = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', 0, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    return, files

end


probe = '11'
time = time_double(['2008-03-14','2008-03-15'])

probe = '16'
time = time_double(['2019-03-19','2019-03-20'])

goes_read_bfield_cdaweb, time, probe=probe
end
