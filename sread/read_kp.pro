;+
; Read KP index.
;-
function parse_kp_treat_space, str

    for kk=0,strlen(str) do begin
        if strmid(str,kk,1) ne ' ' then continue
        str = strmid(str,0,kk)+'0'+strmid(str,kk+1)
    endfor
    return, str
    
end


function load_kp, input_time_range, probe=probe, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

    ;---Check inputs.
    sync_threshold = 0
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'kp'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://datapub.gfz-potsdam.de/download/10.5880.Kp.0001'
    if n_elements(version) eq 0 then version = 'v.*'
    datatype = 'gfz%def'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse


    ;---Init settings.
    type_dispatch = hash()
    valid_range = time_double(['1932-01-01'])
    base_name = 'Kp_def%Y.wdc'
    local_path = [local_root,'Kp_definitive']
    remote_path = [remote_root,'Kp_definitive']
    type_dispatch['gfz%def'] = dictionary($
        'pattern', dictionary($
        'local_file', join_path([local_path,base_name]), $
        'local_index_file', join_path([local_path,default_index_file(/sync)]), $
        'remote_file', join_path([remote_path,base_name]), $
        'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', sync_threshold, $
        'valid_range', valid_range, $
        'cadence', 'year', $
        'extension', fgetext(base_name) )
    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return, ''
    endif

    ;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return, ''
    endif
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return, ''
    endif
    request = type_dispatch[datatype]

    ;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)

    if n_elements(files) eq 0 then return, '' else return, files

end


function read_kp, input_time_range, $
    errmsg=errmsg, get_name=get_name, resolution=resolution, _extra=ex

    var = 'kp'
    if keyword_set(get_name) then return, var

    errmsg = ''
    retval = ''

    time_range = time_double(input_time_range)
    files = load_kp(time_range, errmsg=errmsg)
    if errmsg ne '' then return, retval

    ; Parse the files.
    times = []
    kps = []
    nrec_per_day = 8.
    cadence = 3d*3600    ; h.
    secofday = constant('secofday')
    rec_times = smkarthm(0.5*cadence,secofday-0.5*cadence,nrec_per_day,'n')
    
    
    foreach file, files do begin
        lines = read_all_lines(file)
        nline = n_elements(lines)
        for ii=0,nline-1 do begin
            if strmid(lines[ii],0,1) ne '#' then break
        endfor
        nheader = ii
        ndate = nline-nheader
        the_times = dblarr(ndate,nrec_per_day)
        kp0s = fltarr(ndate,nrec_per_day)
        kp1s = intarr(ndate,nrec_per_day)
        base = file_basename(file)
        date_str = strmid(base, strlen(base)-8,4)
        for ii=0,ndate-1 do begin
            the_line = lines[ii+nheader]
            the_date = parse_kp_treat_space(date_str+strmid(the_line, 2,2)+strmid(the_line, 4,2))
            the_times[ii,*] = time_double(the_date,tformat='YYYYMMDD')+rec_times
            the_kp_str = parse_kp_treat_space(strmid(the_line, 12,nrec_per_day*2))
            for jj=0,nrec_per_day-1 do begin
                the_kp = strmid(the_kp_str,jj*2,2)
                kp0 = float(strmid(the_kp,0,1))
                kp1 = fix(strmid(the_kp,1,1))
                kp0s[ii,jj] = kp0
                kp1s[ii,jj] = kp1
            endfor
        endfor
        dkp = float(kp1s)
        index = where(kp1s eq 3, count)
        if count ne 0 then dkp[index] = 1d/3
        index = where(kp1s eq 7, count)
        if count ne 0 then dkp[index] = 2d/3
        kps = [kps,kp0s+dkp]
        times = [times,the_times]
    endforeach

    times = (transpose(times))[*]
    kps = (transpose(kps))[*]
    store_data, var, times, kps
    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'Kp', $
        'unit', '#' )
    return, var

end


time_range = time_double(['2013','2013-06'])
files = read_kp(time_range)
end