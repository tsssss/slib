;+
; Generate L2 spec v02 cdfs, from L1 data.
;   Use it when the L2 v01 files are missing.
;-

pro rbsp_efw_phasef_gen_l2_spec_v02_from_l1_per_day, date, probe=probe, filename=file, log_file=log_file

    on_error, 0
    errmsg = ''

    msg = 'Processing '+file+' ...'
    lprmsg, msg, log_file

;---Check input.
    if n_elements(file) eq 0 then begin
        errmsg = 'cdf file is not set ...'
        lprmsg, errmsg, log_file
        return
    endif

    if n_elements(probe) eq 0 then begin
        errmsg = 'No input probe ...'
        lprmsg, errmsg, log_file
        return
    endif
    if probe ne 'a' and probe ne 'b' then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        lprmsg, errmsg, log_file
        return
    endif
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    data_type = 'spec'
    valid_range = rbsp_efw_phasef_get_valid_range(data_type, probe=probe)
    if n_elements(date) eq 0 then begin
        errmsg = 'No input date ...'
        lprmsg, errmsg, log_file
        return
    endif
    if size(date,/type) eq 7 then date = time_double(date)
    if product(date-valid_range) gt 0 then begin
        errmsg = 'Input date: '+time_string(date,tformat='YYYY-MM-DD')+' is out of valid range ...'
        lprmsg, errmsg, log_file
        return
    endif


;---Prepare skeleton.
    data_type = 'spec'
    skeleton_base = prefix+'efw-l2_'+data_type+'_00000000_v02.cdf'
    skeleton = join_path([srootdir(),skeleton_base])
    if file_test(skeleton) eq 0 then begin
        errmsg = 'Skeleton file is not found ...'
        lprmsg, errmsg, log_file
        return
    endif


;---Load L1 data.
    timespan, date
    rbsp_load_efw_spec, probe=probe, type='calibrated'


;---Save L1 data to file.
    file_copy, skeleton, file, overwrite=1
    
    time_var = 'epoch'
    time_is_set = 0
    nchannel = 7
    tplot_vars = prefix+'efw_64_spec'+string(findgen(nchannel),format='(I0)')
    foreach var, tplot_vars do begin
        get_data, var, data=tmp, dlimits=dlim, limits=lim
        if not is_struct(tmp) then continue
        channel = strlowcase(dlim.data_att.channel)
        cdf_var = 'spec64_'+channel
        cdf_save_data, cdf_var, value=transpose(tmp.y), filename=file
        if time_is_set eq 0 then begin
            epochs = convert_time(tmp.x, from='unix', to='epoch16')
            cdf_save_data, time_var, value=epochs, filename=file
            time_is_set = 1
        endif
    endforeach
    
;
;    ; Need to be consistent with L2 v01 labels.
;    var = 'efw_flags_all'
;    time_var = 'epoch_qual'
;    
;    cdf_rename_var, 'epoch_flags', to=time_var, filename=file
;    cdf_save_setting, 'DEPEND_0', time_var, varname=var, filename=file
;    
;    cdf_rename_var, 'efw_flags_labl', to='efw_qual_labl', filename=file
;    cdf_save_setting, 'LABL_PTR_1', 'efw_qual_labl', varname=var, filename=file
;
;    cdf_rename_var, 'efw_flags_compno', to='efw_qual_compno', filename=file
;    cdf_save_setting, 'LABLAXIS', 'efw_qual_compno', varname=var, filename=file
;    
;    cdf_rename_var, var, to='efw_qual', filename=file
;    stop


;---Use the phase F flags.
    rbsp_efw_phasef_read_efw_qual, date, probe=probe, errmsg=errmsg, log_file=log_file
    var = 'efw_qual'
    var_setting = cdf_read_setting(var, filename=file)
    time_var = var_setting['DEPEND_0']
    time_var_setting = cdf_read_setting(time_var, filename=file)
    secofday = constant('secofday')
    get_data, prefix+var, times, flags
    epochs = convert_time(times, from='unix', to='epoch16')
    cdf_del_var, time_var, filename=file
    cdf_save_var, time_var, value=epochs, filename=file
    cdf_save_setting, time_var_setting, filename=file, varname=time_var
    cdf_del_var, var, filename=file
    cdf_save_var, var, value=flags, filename=file
    cdf_save_setting, var_setting, filename=file, varname=var
    rbsp_efw_phasef_save_efw_qual_to_file, date, probe=probe, filename=file


;---Remove dummy variables.
    cdf_del_unused_vars, file


;---Fix labeling for spec??_scm??.
    unit = 'nT^2/Hz'
    all_vars = cdf_vars(file)
    foreach var, all_vars do begin
        if (strpos(var, 'scm'))[0] ne -1 then begin
            cdf_save_setting, 'UNITS', unit, filename=file, varname=var
        endif
    endforeach


;---Fix time tag offset.
    time_tag_offset = -4d
    time_var = 'epoch'
    epoch = cdf_read_var(time_var, filename=file)
    times = convert_time(epoch, from='epoch16', to='unix')+time_tag_offset
    epoch = convert_time(times, from='unix', to='epoch16')
    cdf_save_data, time_var, value=epoch, filename=file


;---ISTP format.
    rbsp_efw_phasef_gen_l2_spec_v02_skeleton, file

end


stop
; This block is used to generate the L2 v02 spec files directly from L1 files.
; L1 files are available throughout the mission, no missing days.
; L2 v01 files are missing for some days.
; The previous L2 v02 files are modified from the L2 v01 files, therefore are missing for the same days as L2 v01.
; Now L2 v02 files are available throughout the mission, no missing days. -Sheng, 2022-08-06.
; 
; Find all days with missing L2 data but exisitng L1 data.
secofday = 86400d
probes = ['a','b']
remote_root = 'http://themis.ssl.berkeley.edu/data/rbsp/'
local_root = '/Volumes/data/rbsp/'
missing_info = dictionary()

foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    time_range = rbsp_efw_phasef_get_valid_range('spec', probe=probe)
    days = make_bins(time_range+[0,-1]*secofday, secofday)
    missing_info[probe] = dictionary($
        'l1', list(), $
        'l2', list() )

    foreach day, days do begin
        year_str = time_string(day,tformat='YYYY')
        date_str = time_string(day,tformat='YYYYMMDD')
        l1_base = prefix+'l1_spec_64_'+date_str+'_v*.cdf'
        l1_remote_url = join_path([remote_root,rbspx,'l1','spec',year_str,l1_base])
        spd_download_expand, l1_remote_url, last_version=1, $
            ssl_verify_peer=0, ssl_verify_host=0
        if l1_remote_url eq '' then begin
            missing_info[probe].l1.add, l1_remote_url
            continue    ; No L1 file
        endif else begin
            l2_base = prefix+'efw-l2_spec_'+date_str+'_v02.cdf'
            l2_local_file = join_path([local_root,rbspx,'l2','spec_v02',year_str,l2_base])
            
            l2_v01_base = prefix+'efw-l2_spec_'+date_str+'_v01.cdf'
            l2_v01_local_file = join_path([local_root,rbspx,'l2','spec_v01',year_str,l2_v01_base])
            if file_test(l2_v01_local_file) eq 0 then begin
                missing_info[probe].l2.add, l2_local_file
                rbsp_efw_phasef_gen_l2_spec_v02_from_l1_per_day, day, probe=probe, filename=l2_local_file
                continue
            endif
        endelse
    endforeach
endforeach
stop

tab = '    '
log_file = join_path([srootdir(),'rbsp_efw_phasef_l1_spec_missing_files.txt'])
if file_test(log_file) eq 1 then file_delete, log_file
ftouch, log_file
foreach probe, probes do begin
    lprmsg, '', log_file
    lprmsg, 'RBSP-'+strupcase(probe), log_file
    foreach file, missing_info[probe].l1 do lprmsg, tab+file, log_file
endforeach

log_file = join_path([srootdir(),'rbsp_efw_phasef_l2_spec_v01_missing_files.txt'])
if file_test(log_file) eq 1 then file_delete, log_file
ftouch, log_file
foreach probe, probes do begin
    lprmsg, '', log_file
    lprmsg, 'RBSP-'+strupcase(probe), log_file
    foreach file, missing_info[probe].l2 do lprmsg, tab+file, log_file
endforeach
stop


day = time_double('2018-09-27')
;day = '2018-09-26'
probe = 'a'
file = join_path([homedir(),'rbspa_efw-l2_spec_'+time_string(day,tformat='YYYYMMDD')+'_v02.cdf'])
rbsp_efw_phasef_gen_l2_spec_v02_from_l1_per_day, day, probe=probe, filename=file
end