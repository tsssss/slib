;+
; Read RBSP SDT flag, where 1 is for during SDT.
;
; time. A time or a time range in ut time. Set time to find files
;   automatically, or set files to read data in them directly.
; id=. A string sets the data type to read. Check supported ids by setting
;   print_datatype.
; print_datatype=. A boolean. Set to print all supported ids.
; probe=. A string set the probe to read data for.
; local_root=. A string to set the local root directory.
; remote_root=. A string to set the remote root directory.
; local_files=. A string or an array of N full file names. Set to fine
;   tuning the files to read data from.
; file_times=. An array of N times. Set to fine tuning the times of the files.
; version=. A string to set specific version of files. By default, the
;   program finds the files of the highest version.
;-

pro rbsp_read_sdt_flag_gen_file, time, probe=probe, filename=data_file, errmsg=errmsg, local_root=local_root
;---Internal, do not check inputs.
    local_root = join_path([default_local_root(),'data','rbsp'])
    remote_root = 'http://themis.ssl.berkeley.edu/data/rbsp'
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_l1_hsk_beb_analog_%Y%m%d_v.*.cdf'
    type = 'hsk_beb_analog'
    local_path = [local_root,rbspx,'efw','l1',type,'%Y']
    remote_path = [remote_root,rbspx,'l1',type,'%Y']
    sync_threshold = 0
    suffix = ['1','2','3','4','5','6']
    request = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['IEFI_GUARD'+suffix,'IEFI_USHER'+suffix], $
                'out_vars', rbspx+'_'+['guard'+suffix,'usher'+suffix], $
                'time_var_name', 'hdr_epoch', $
                'time_var_type', 'epoch16')))

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)

;---Read data from files and save to memory.
    read_files, time, files=files, request=request


;---Load data and search for SDT around apogee.
    prefix = 'rbsp'+probe+'_'
    data_rate = 60. ; sec.
    year = fix(time_string(time,tformat='YYYY'))
    full_time_range = time_double([string(year,format='(I4)'),string(year+1,format='(I4)')])
    common_times = smkarthm(full_time_range[0], full_time_range[1]-data_rate*0.5, data_rate, 'dx')
    ncommon_time = n_elements(common_times)
    sdt_flags = intarr(ncommon_time)

    ; Use orbit data to eliminate perigee.
    rbsp_read_orbit, time, probe=probe
    apogee_limit = 4.
    orbit_time_step = 60.
    dis = snorm(get_var_data(prefix+'r_gsm', times=orbit_times))
    index = where(dis ge apogee_limit)
    apogee_time_ranges = time_to_range(orbit_times[index], time_step=orbit_time_step)
    napogee_time_range = n_elements(apogee_time_ranges)/2

    ; Use gaurd1 and guard6 to get the time range.
    time_ranges = list()
    step = 5.
    for ii=0, napogee_time_range-1 do begin
        the_time_range = reform(apogee_time_ranges[ii,*])
;        lprmsg, 'Processing orbit: '+time_string(the_time_range)+' ...'
;        guard1 = get_var_data(prefix+'guard1', in=the_time_range, times=times)
;        ; There could be no data. This is the normal case.
;        if n_elements(guard1) eq 0 then continue
;        guard_values = sort_uniq(guard1)
;        ; There could be just 1 value. This is the normal case.
;        if n_elements(guard_values) eq 1 then continue
;        ; There could be 2 values. This is not SDT, but creates spikes in Vsc. Or is eclipse. Or mode change?
        ; There could be a range of values. This is SDT.
        ; In these cases, we will flag when values are different from the start and end values.
        start_time = []
        end_time = []
        foreach the_suffix, suffix do begin
            foreach var, prefix+['usher','guard']+the_suffix do begin
                data = get_var_data(var, in=the_time_range, times=times)
                if n_elements(data) eq 0 then continue
                data = round(data/step)*step
                values = sort_uniq(data)
                nvalue = n_elements(values)
                if nvalue le 2 then continue

                index = where(data ne data[0])
                if index[0] eq -1 then continue
                the_index = index[0]
                if the_index gt 0 then the_index -= 1
                start_time = [start_time, times[the_index]]

                index = where(data ne data[-1])
                if index[0] eq -1 then continue
                the_index = index[-1]
                if the_index lt n_elements(times)-1 then the_index += 1
                end_time = [end_time, times[the_index]]
            endforeach
        endforeach
        if n_elements(start_time) eq 0 then continue
        if n_elements(end_time) eq 0 then continue
        start_time = min(start_time)
        end_time = max(end_time)
        if end_time le start_time then continue
        time_ranges.add, [start_time, end_time]
;        plot_file = join_path([homedir(),'test_sdt_flag','fig_sdt_flag_'+rbspx+'_'+time_string(start_time,tformat='YYYY_MMDD_hhmm')+'.pdf'])
;        sgopen, plot_file, xsize=5, ysize=8, /inch
;        tplot, prefix+'guard?', trange=the_time_range
;        timebar, time_ranges[-1], color=sgcolor('red')
;        sgclose
    endfor
    if n_elements(time_ranges) eq 0 then begin
        time_ranges = []
        ntime_range = 0
    endif else begin
        time_ranges = transpose(time_ranges.toarray())  ; in [2,n].
        ntime_range = n_elements(time_ranges[0,*])
    endelse

    ; Combine to the overall times.
    data_rate = 60. ; sec.
    year = fix(time_string(time[0],tformat='YYYY'))
    full_time_range = time_double([string(year,format='(I4)'),string(year+1,format='(I4)')])
    common_times = smkarthm(full_time_range[0], full_time_range[1]-data_rate*0.5, data_rate, 'dx')
    ncommon_time = n_elements(common_times)
    sdt_flags = intarr(ncommon_time)
    for ii=0, ntime_range-1 do begin
        the_time_range = time_ranges[*,ii]
        the_time_range = the_time_range-(the_time_range mod data_rate)
        if (time_ranges[1,ii] mod data_rate) eq 0 then the_time_range[1] += data_rate
        index = lazy_where(common_times, '[]', the_time_range, count=count)
        if count eq 0 then continue
        sdt_flags[index] = 1
    endfor

;---Write to file.
    pre0 = 'rbsp'+probe+'_'
    odir = fgetpath(data_file)
    if file_test(odir,/directory) eq 0 then file_mkdir, odir
    offn = data_file
    if file_test(offn) eq 1 then file_delete, offn  ; overwrite old files.

    ginfo = {$
        title: 'RBSP flag to tell if SDT is going on or not',$
        text: 'Generated by Sheng Tian at the University of Minnesota'}
    scdfwrite, offn, gattribute=ginfo

    ; utsec.
    utname = 'ut_flag'
    ainfo = {$
        fieldnam: 'UT time', $
        units: 'sec', $
        var_type: 'support_data'}
    scdfwrite, offn, utname, value=common_times, attribute=ainfo, cdftype='CDF_DOUBLE'

    ; sdt_flag.
    varname = 'sdt_flag'
    tdat = sdt_flags
    ainfo = {$
        fieldnam: 'SDT flag: 1 for during SDT', $
        units: '#', $
        var_type: 'data', $
        depend_0: utname}
    scdfwrite, offn, varname, value=tdat, attribute=ainfo

end


pro rbsp_read_sdt_flag, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','rbsp'])
    if n_elements(version) eq 0 then version = 'v01'

;---Init settings.
    type_dispatch = hash()
    valid_range = ['2012','2020']
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_sdt_flag_%Y_'+version+'.cdf'
    local_path = [local_root,rbspx,'flags','sdt']

    request = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'year', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['sdt_flag'], $
                'out_vars', rbspx+'_'+['sdt_flag'], $
                'time_var_name', 'ut_flag', $
                'time_var_type', 'unix')))

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            year = time_string(file_time,tformat='YYYY')
            the_time_range = time_double([string(year,format='(I4)'),string(year+1,format='(I4)')])
            local_file = file.local_file
            rbsp_read_sdt_flag_gen_file, the_time_range, probe=probe, filename=local_file, local_root=local_root
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif

;---Read data from files and save to memory.
    read_files, time, files=files, request=request

end

foreach probe, ['a','b'] do rbsp_read_sdt_flag, time_double(['2012-01-01','2020-01-01']), probe=probe
end
