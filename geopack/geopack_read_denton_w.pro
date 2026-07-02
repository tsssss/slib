;+
; Read Denton solar-wind/geopack parameter file.
;
; The default file is test/solarwind.txt under this geopack directory.
;-

function geopack_read_denton_w, input_time_range, file=input_file, prefix=input_prefix, $
    get_name=get_name, update=update, errmsg=errmsg, _extra=extra
    compile_opt idl2

    errmsg = ''
    retval = ''

    if n_elements(input_prefix) eq 0 then prefix = 'denton_' else prefix = input_prefix


    time_range = time_double(input_time_range)

    var_info = prefix+'w'
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then tmp = delete_var_from_memory(var_info)
    if ~check_if_update_memory(var_info, time_range) then return, var_info

    if n_elements(input_file) eq 0 then begin
        file = join_path([srootdir(),'solarwind.txt'])
    endif else begin
        file = input_file
    endelse
    if file_test(file) eq 0 then begin
        errmsg = handle_error('Denton file not found: '+file)
        return, retval
    endif

    lines = read_all_lines(file)

    ; Find header line.
    header_str = ' Year Day Hr  ByIMF  BzIMF   V_SW  Den_P   Pdyn     G1     G2     G3  8 status     kp   akp3    dst    Bz1    Bz2    Bz3    Bz4    Bz5    Bz6       W1       W2       W3       W4       W5       W6     12 status'
    nline = n_elements(lines)
    header_line = -1L
    for ii=0L, nline-1L do begin
        if lines[ii] eq header_str then begin
            header_line = ii
            break
        endif
    endfor
    if header_line lt 0 then begin
        errmsg = handle_error('Denton header line not found in: '+file)
        return, ''
    endif

    ; Read all data.
    ntime_all = nline-header_line-1L
    time_strs = strarr(ntime_all)
    imf_by = fltarr(ntime_all)
    imf_bz = fltarr(ntime_all)
    v_sw = fltarr(ntime_all)
    den = fltarr(ntime_all)
    pdyn = fltarr(ntime_all)
    g_params = fltarr(ntime_all,3)
    kp = fltarr(ntime_all)
    kp3 = fltarr(ntime_all)
    dst = fltarr(ntime_all)
    bzs = fltarr(ntime_all,6)
    w_params = fltarr(ntime_all,6)

    for ii=header_line+1L, nline-1L do begin
        jj = ii-header_line-1L
        info = strsplit(lines[ii], ' ', extract=1)
        if n_elements(info) lt 28 then continue

        time_strs[jj] = info[0]+'-'+string(info[1], format='(I03)')+'-'+ $
            string(info[2], format='(I02)')
        imf_by[jj] = float(info[3])
        imf_bz[jj] = float(info[4])
        v_sw[jj] = float(info[5])
        den[jj] = float(info[6])
        pdyn[jj] = float(info[7])
        g_params[jj,0:2] = float(info[8:10])
        kp[jj] = float(info[12])
        kp3[jj] = float(info[13])
        dst[jj] = float(info[14])
        bzs[jj,0:5] = float(info[15:20])
        w_params[jj,0:5] = float(info[21:26])
    endfor

    times_all = time_double(time_strs, tformat='YYYY-DOY-hh')
    time_index = where_pro(times_all, '[]', time_range, count=ntime)
    if ntime eq 0 then begin
        errmsg = handle_error('No Denton data in requested time range.')
        return, ''
    endif

    times = times_all[time_index]
    ndim = n_elements(w_params[0,*])
    colors = get_color(ndim)
    settings = dictionary($
        'requested_time_range', time_range, $
        'display_type', 'stack', $
        'labels', 'W'+string(findgen(ndim)+1,format='(I0)'), $
        'colors', colors, $
        'ylog', 1, $
        'ytitle', 'W Param')
    tmp = var_store(var_info, w_params[time_index,*], times, settings=settings)

    return, var_info

end

compile_opt idl2
time_range = time_double(['2000-222','2000-227'],tformat='YYYY-DOY')
w_var = geopack_read_denton_w(time_range)
sgopen, 0, size=[6,2]
tplot, w_var, trange=time_range
end