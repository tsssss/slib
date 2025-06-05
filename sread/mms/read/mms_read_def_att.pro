;+
; A wrapper for mms_read_def_att_file. It doesn't handle the last line correctly.
;-

function mms_read_def_att, vars, filename=file, errmsg=errmsg

    errmsg = ''
    retval = !null
    
    lines = strtrim(read_all_lines(file),2)
    nline = n_elements(lines)
    
    ; Read headers.
    headers = list()
    foreach line, lines, the_lid do begin
        if line eq 'META_START' then break
        headers.add, line
    endforeach
    
    
    ; Read meta data.
    gatts = list()
    for lid=the_lid,nline-1 do begin
        line = lines[lid]
        if line eq 'META_STOP' then break
        gatts.add, line
        the_lid += 1
    endfor
    
    ; Read vars.
    columns = ['Time (UTC)','Elapsed Sec','q1','q2','q3','qc', $
        'wX','wY','wZ','w-Phase', $
        'Z-RA','Z-Dec','Z-Phase', $
        'L-RA','L-Dec','L-Phase', $
        'P-RA','P-Dec','P-Phase', $
        'Nut', 'QF']
    columns = strlowcase(columns)
    valid_vars = ['time','elapsed_sec','q1','q2','q3','qc', $
        'w'+['x','y','z','_phase'], $
        'z_'+['ra','dec','phase'], $
        'l_'+['ra','dec','phase'], $
        'p_'+['ra','dec','phase'], $
        'nut','qf']
    nvar = n_elements(vars)
    var_index = fltarr(nvar)
    foreach var, vars, vid do begin
        var_index[vid] = where(valid_vars eq var, count)
        if count eq 0 then begin
            errmsg = 'Var does not exist: '+var+' ...'
            return, retval
        endif
    endforeach

    the_data = mms_read_def_att_file(file)
    i0 = (where(lines eq 'DATA_START'))[0]
    i1 = (where(lines eq 'DATA_STOP'))[0]
    ntime = i1-i0-2 ; there is a comment line after data_start.
    data_info = dictionary()
    time_var = 'time'
    tformat = 'YYYY-DOYThh:mm:ss.fff'
    ii = 0
    data_info[time_var] = time_double((the_data.(ii))[0:ntime-1],tformat=tformat)
    foreach var, vars do begin
        ii = (where(valid_vars eq var))[0]
        tmp = (the_data.(ii))[0:ntime-1]
        if var ne 'qf' then tmp = double(tmp)
        data_info[valid_vars[ii]] = tmp
    endforeach
    
    return, data_info

end
