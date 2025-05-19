;+
; Test whether b1 split files contain the same data as the original files.
;-

probes = ['a','b']
type = 'vb1'
ntest_file = 10

log_file = join_path([srootdir(),'test_b1_split_and_original_files_'+type+'.log'])
if file_test(log_file) eq 0 then ftouch, log_file
root_dir = join_path([rbsp_efw_phasef_local_root()])
foreach probe, probes do begin
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'
    files = file_search(join_path([root_dir,rbspx,'l1',type,'*','*v02.cdf']))

    ; Sort by file size.
    nfile = n_elements(files)
    file_sizes = fltarr(nfile)
    foreach file, files, file_id do begin
        finfo = file_info(file)
        file_sizes[file_id] = finfo.size
    endforeach
    index = sort(file_sizes)
    file_sizes = file_sizes[index]
    files = files[index]

    ; Select some files to check.
    test_index = floor(smkarthm(0,nfile,ntest_file,'n'))
    test_files = files[test_index]
    file_sizes = file_sizes[test_index]

    ; Check the first 30 min of data.
    duration = 30*60d
    pad_time = 2*60d
    foreach test_file, test_files, file_id do begin
        lprmsg, '', log_file
        lprmsg, 'Checking '+test_file+' ...', log_file
        lprmsg, 'File size: '+string(file_sizes[file_id]*1e-6)+' MB ...', log_file
        
        epochs = cdf_read_var('epoch', filename=test_file)
        times = convert_time(epochs, from='epoch16', to='unix')
        time_range = times[0]+[0,duration]
        the_time_range = time_range+[1,-1]*pad_time
        
        ; Get the wanted data.
        index = where_pro(times, '[]', time_range, count=ntime)
        times = times[index]
        data_orig = cdf_read_var(type, filename=test_file, range=[0,ntime-1])
        
        index = where_pro(times, '[]', the_time_range)
        data_orig = data_orig[index,*]
        times = times[index]
        index = uniq(times, sort(times))
        data_orig = data_orig[index,*]
        times = times[index]
        
        ; Get the wanted split data.
        rbsp_efw_phasef_read_b1_split, time_range, probe=probe, id=type
        data_split = get_var_data(prefix+'vb1', times=split_times)
        
        index = where_pro(split_times, '[]', the_time_range)
        data_split = data_split[index,*]
        split_times = split_times[index]
        index = uniq(split_times, sort(split_times))
        data_split = data_split[index,*]
        split_times = split_times[index]
        
        norig_data = n_elements(data_orig[*,0])
        nsplit_data = n_elements(data_split[*,0])
        if norig_data ne nsplit_data then begin
            lprmsg, 'Inconsistent # of data ...', log_file
            lprmsg, '# of orig data: '+string(norig_data), log_file
            lprmsg, '# of split data: '+string(nsplit_data), log_file
            data_split = sinterpol(data_split, split_times, times)
        endif
        
        tmp = data_orig-data_split
        if tmp[0] ne 0 or tmp[1] ne 0 then begin
            lprmsg, 'Different data ...', log_file
            lprmsg, 'max diff: '+string(max(tmp)), log_file
            lprmsg, 'min diff: '+string(min(tmp)), log_file
            lprmsg, 'mean diff: '+string(mean(tmp)), log_file
            lprmsg, 'stddev diff: '+string(stddev(tmp)), log_file
        endif else begin
            lprmsg, 'Same data ...', log_file
        endelse
    endforeach
endforeach

end
