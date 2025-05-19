;+
; Read the flag for shadow spike.
;-

function rbsp_efw_phasef_read_flag_shadow_spike_parse_file, file

    lines = read_all_lines(file)
    nline = n_elements(lines)
    if nline eq 0 then begin
        times = []
        duras = []
    endif else begin
        nhead = 5
        ntime = nline-nhead
        times = dblarr(ntime)
        duras = dblarr(ntime)
        for ii=0,ntime-1 do begin
            tline = lines[ii+nhead]
            infos = strsplit(tline,',', extract=1)
            times[ii] = time_double(infos[0],tformat='YYYY-MM-DDThh:mm:ss.fff')
            duras[ii] = double(infos[1])
        endfor
    endelse
    
    return, dictionary('times', times, 'duras', duras)
    
end

function rbsp_efw_phasef_read_shadow_spike_time, time_range, probe=probe

    prefix = 'rbsp'+probe+'_'
    flag_var = prefix+'efw_phasef_shadow_spike_time'


    valid_range = (probe eq 'a')? ['2012-09-24','2019-10-13/24:00']: ['2012-09-24','2019-07-16/24:00']
    base_name = strupcase('rbsp-'+probe)+'_SP5antinshadow_YYYY-MM-DD_v*.txt'
    remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp/documents/emfisis/emfisis.physics.uiowa.edu/Events'
    remote_path = [remote_root,'rbsp-'+probe,'SP5antinshadow',base_name]
    local_root = join_path([rbsp_efw_phasef_local_root()])
    local_path = [local_root,'efw_flag','flags','rbsp'+probe,'YYYY',base_name]

    local_files = file_dailynames(file_format=join_path(local_path), trange=time_range)
    remote_files = file_dailynames(file_format=join_path(remote_path), trange=time_range)

    local_files = rbsp_efw_read_xxx_download_files(local_files, remote_files)
    if n_elements(local_files) eq 0 then return, []
    times = []
    duras = []
    foreach local_file, local_files do begin
        info = rbsp_efw_phasef_read_flag_shadow_spike_parse_file(local_file)
        times = [times,info.times]
        duras = [duras,info.duras]
    endforeach
    
    return, [[times],[times+duras]]

end

time_range = time_double(['2012-10-01','2012-10-03'])
probe = 'a'
trs = rbsp_efw_phasef_read_shadow_spike_time(time_range, probe=probe)
end