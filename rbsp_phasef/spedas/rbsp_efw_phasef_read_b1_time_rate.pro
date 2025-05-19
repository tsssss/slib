;+
; Read b1 time and rate. Adopted from Aaron's burst1_times_rates_RBSPx.txt.
; Fixed sections with non-standard sample rates, i.e., those are not 0.5,1,2,4,8,16k S/s.
; Also, Sections spanning two days are handled properly now.
;
; datatype=. Can be 'vb1' or 'mscb1'.
;-

function rbsp_efw_phasef_read_b1_time_rate, time_range, probe=probe, datatype=datatype, $
    get_name=get_name, $
    level=level, verbose=verbose, downloadonly=downloadonly, $
    cdf_data=cdf_data,get_support_data=get_support_data, $
    tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
    varformat=varformat, valid_names = valid_names, files=files, $
    type=type, _extra = _extra

    retval = !null

    if n_elements(probe) eq 0 then probe = 'a'
    prefix = 'rbsp'+probe+'_'
    if n_elements(datatype) eq 0 then datatype = 'vb1'
    var_info = prefix+'efw_'+datatype+'_time_rate'
    if keyword_set(get_name) then return, var_info

    rbsp_efw_init
    vb = keyword_set(verbose) ? verbose : 0
    vb = vb > !rbsp_efw.verbose

    if n_elements(version) eq 0 then version = 'v*'
;    if n_elements(trange) ne 0 then time_range = trange
;    if n_elements(time_range) eq 0 then time_range = timerange()
;    if size(time_range[0],/type) eq 7 then time_range = time_double(time_range)
;    timespan, time_range[0], total(time_range*[-1,1]), /seconds
    data_types = ['vb1','mscb1']
    index = where(data_types eq datatype[0], count)
    if count eq 0 then begin
        dprint, 'Invalid datatype: '+datatype[0]+' ...', verbose=vb
        return, retval
    endif
    datatype = 'vb1'    ; 'mscb1' is the same.

    rbspx = 'rbsp'+probe
    base = rbspx+'_efw_l1_'+datatype+'_time_rate_v01.cdf'
    base_remote = rbspx+'_l1_'+datatype+'_time_rate_v01.cdf'
    local_root = !rbsp_efw.local_data_dir
    local_path = [local_root,rbspx,'efw','l1',datatype+'-split',base]
    remote_root = rbsp_efw_remote_root()
;    remote_path = [remote_root,rbspx,(rbsp_efw_remote_sub_dirs(level='l1',datatype=datatype+'-split'))[0:-2],base]  ; remove YYYY.
    remote_path = [remote_root,'documents','efw',base_remote]  ; remove YYYY.
    local_file = join_path(local_path)
    remote_file = join_path(remote_path)

    url = remote_file
    spd_download_expand, url, last_version=1, $
        ssl_verify_peer=0, ssl_verify_host=0, _extra=_extra
    base = file_basename(url)
    local_file = join_path([file_dirname(local_file),base])
    tmp = spd_download_file(url=url, filename=local_file, ssl_verify_peer=0, ssl_verify_host=0)

    time_ranges = cdf_read_var('time_range', filename=local_file)
    sample_rate = cdf_read_var('median_sample_rate', filename=local_file)

    store_data, var_info, time_ranges[*,0], time_ranges, float(sample_rate)
    add_setting, var_info, dictionary($
        'requested_time_range', time_range)
    return, var_info

end

probes = ['a','b']
foreach probe, probes do rbsp_efw_phasef_read_b1_time_rate, probe=probe
end
