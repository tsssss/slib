;+
; Read spice var (Spacecraft position, attitude, spin info, etc).
;-

pro rbsp_efw_read_spice_var, tr, probe=probe, datatype=datatype, trange=trange, $
    level=level, verbose=verbose, downloadonly=downloadonly, $
     cdf_data=cdf_data,get_support_data=get_support_data, $
     tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
     varformat=varformat, valid_names = valid_names, files=files, $
     type=type, _extra = _extra

    rbsp_efw_init
    vb = keyword_set(verbose) ? verbose : 0
    vb = vb > !rbsp_efw.verbose

    if n_elements(probe) eq 0 then probe = 'a'
    if n_elements(version) eq 0 then version = 'v08'
    if n_elements(trange) ne 0 then time_range = trange
    if n_elements(tr) ne 0 then time_range = tr
    if n_elements(time_range) eq 0 then time_range = timerange()
    if size(time_range[0],/type) eq 7 then time_range = time_double(time_range)


    rbspx = 'rbsp'+probe
    base = rbspx+'_spice_products_YYYYMMDD_'+version+'.cdf'
    local_root = !rbsp_efw.local_data_dir
    local_path = [local_root,rbspx,'ephemeris','efw-ephem','YYYY',base]
    remote_root = rbsp_efw_remote_root()
    remote_path = [remote_root,rbspx,'ephemeris','efw-ephem','YYYY',base]
    local_files = file_dailynames(file_format=join_path(local_path), trange=time_range)
    remote_files = file_dailynames(file_format=join_path(remote_path), trange=time_range)


    local_files = rbsp_efw_read_xxx_download_files(local_files, remote_files)
    nfile = n_elements(local_files)
    if nfile eq 0 then return


    suffix = ''
    prefix = ''
    cdf2tplot, file=local_files, all=0, prefix=prefix, suffix=suffix, verbose=vb, $
        tplotnames=tns, convert_int1_to_int2=1, get_support_data=0, load_labels=1

end


tr = ['2013-05-01','2013-05-02']
probe = 'a'
rbsp_efw_read_spice_var, tr, probe=probe
end