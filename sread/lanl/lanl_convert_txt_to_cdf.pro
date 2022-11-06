;+
; Read data out of LANL txt data file.
;-
;

function lanl_read_txt_data_parse_value, string
    ; Only deal with the low-level strings, i.e., those contain no nested structures.
    ; So far, only the following types are noticed:
    ;   * string. Enclosed by " ... ",
    ;   * array. Enclosed by [ ... ],
    ;   * number. Enclosed by nothing.
    ;
    ; Structures are enclosed by { ... }, which should be treated outside this program.

    string_open_char = '"'
    string_close_char = '"'
    array_open_char = '['
    array_close_char = ']'
    entry_separator = ','

    value = strtrim(string,2)
    case strmid(value[0],0,1) of
        string_open_char: begin
            value = strmid(value,strpos(value,string_open_char)+1)
            value = strmid(value,0,strpos(value,string_close_char))
            return, value
        end
        array_open_char: begin
            value = strmid(value,strpos(value,array_open_char)+1)
            value = strmid(value,0,strpos(value,array_close_char))
            str_values = strsplit(value,entry_separator,/extract)
            nvalue = n_elements(str_values)
            values = replicate(lanl_read_txt_data_parse_value(str_values[0]),nvalue)
            for ii=1, nvalue-1 do values[ii] = lanl_read_txt_data_parse_value(str_values[ii])
            return, values
        end
        else: return, float(value)
    endcase
end



;+
; skip_fix_nan. A boolean, set to skip replace fill value to nan. Used
;   when converting data to CDF.
;-
function lanl_read_txt_data, file, errmsg=errmsg, skip_fix_nan=skip_fix_nan

    errmsg = ''
    retval = !null

    nfile = n_elements(file)
    if nfile eq 0 then begin
        errmsg = handle_error('No file is given ...')
        return, retval
    endif

    if file_test(file) eq 0 then begin
        errmsg = handle_error('File does not exist ...')
        return, retval
    endif

;---Read all lines, then parse header to find all variables.
    lines = read_all_lines(file)
    nline = n_elements(lines)
    if nline eq 0 then begin
        errmsg = handle_error('No data in file ...')
        return, retval
    endif

    ; Remove empty lines.
    index = where(lines ne '', nline)
    if nline eq 0 then begin
        errmsg = handle_error('No data in file ...')
        return, retval
    endif
    lines = lines[index]

    ; Header starts with #
    header_char = '#'
    nheader = 0
    for ii=0, nline-1 do begin
        if strmid(lines[ii],0,1) ne header_char then break
        nheader += 1
    endfor
    headers = lines[0:nheader-1]
    data_lines = lines[nheader+1:*]
    ntime = n_elements(data_lines)


    ; Parse header to get gatt and vatt.
    value_separator = ':'
    group_open_char = '{'
    group_close_char = '}'

    ; Each attribute is separated by an empty line following #.
    gatt = {natts: 0}
    var = {nvar: 0}
    for ii=0, nheader-2 do begin
        tline = strtrim(strmid(headers[ii],1),2) ; remove the leading # and white spaces.
        ; Separate the name and value.
        pos = (strpos(tline, value_separator))[0]
        if pos eq -1 then continue
        tag_name = strmid(tline, 0, pos)
        values = strmid(tline, pos+1)
        repeat begin
            ii += 1
            next_line = strmid(strmid(headers[ii],1),2)
            if next_line eq '' then break
            values = [values,next_line]
        endrep until next_line eq ''

        tag_name = lanl_read_txt_data_parse_value(tag_name)

        natt_value = n_elements(values)
        time_var = 'DateTime'   ; case sensitive.
        if natt_value eq 1 then begin
            ; The entry is a global attribute.
            att_name = tag_name
            att_value = lanl_read_txt_data_parse_value(values[0])
            gatt = create_struct(att_name, att_value, gatt)
            gatt.natts += 1
        endif else begin
            ; The entry is a variable attribute.
            var_name = tag_name
            vatt = {natts: natt_value}
            pos = (strpos(values[0],group_open_char))[0]
            if pos ne -1 then values[0] = strmid(values[0],pos+1)
            pos = (strpos(values[natt_value-1],group_close_char))[0]
            if pos ne -1 then values[natt_value-1] = strmid(values[natt_value-1],0,pos)
            has_data = 0
            for jj=0, natt_value-1 do begin
                tvalue = values[jj]
                pos = strpos(tvalue,value_separator)
                vatt_name = lanl_read_txt_data_parse_value(strmid(tvalue,0,pos))
                if vatt_name eq 'VALUES' then begin
                    has_data = 1
                    data = lanl_read_txt_data_parse_value(strmid(tvalue,pos+1))
                endif else begin
                    vatt_value = lanl_read_txt_data_parse_value(strmid(tvalue,pos+1))
                    vatt = create_struct(vatt_name,vatt_value, vatt)
                endelse
            endfor
            dims = ntime
            if stagexist('DIMENSION', vatt) then dims = [ntime, vatt.dimension]
            if has_data then begin
                dims = size(data,/dimensions)
                value = ptr_new(data)
            endif else begin
                value = ptr_new()
                if strlowcase(var_name) ne strlowcase(time_var) then vatt = create_struct('DEPEND_0',time_var, vatt)
            endelse

            var_info = {name:var_name, value:value, nrecs:ntime, dims:dims, att:vatt}
            var = create_struct(var_name, var_info, var)
            var.nvar += 1
        endelse
    endfor

    if var.nvar eq 0 then begin
        return, {__name: 'lanl_txt', $
            header: {__name: 'lanl_txt.header'}, $
            gatt: gatt, $
            var: var}
    endif


;---Read all data, each line is one time, columns are space separated.
    data_separator = ' '
    ncolumn = n_elements(strsplit(data_lines[0],data_separator,/extract))
    str_data = strarr(ntime,ncolumn)
    for ii=0, ntime-1 do str_data[ii,*] = strsplit(data_lines[ii],data_separator,/extract)

    tag_names = tag_names(var)
    var_names = tag_names[where(tag_names ne 'NVAR')]
    foreach var_name, var_names, ii do begin
        var_index = where(tag_names eq var_name)
        if ptr_valid(var.(var_index).value) then continue   ; already got data.
        ; Read data.
        var_info = var.(var_index).att
        if ~stagexist('START_COLUMN', var_info) then continue
        start_column = var_info.start_column
        end_column = start_column
        if stagexist('DIMENSION', var_info) then end_column += var_info.dimension-1
        str_value = reform(str_data[*,start_column:end_column])
        case var_info.name of
            'IsoDateTime': data = time_double(str_value,tformat='YYYY-MM-DDThh:mm:ss.fffZ')
            'Date': data = long(str_value)
            else: data = float(str_value)
        endcase
        var.(var_index).value = ptr_new(data)
    endforeach


    ; Check for invalid data.
    if keyword_set(skip_fix_nan) then begin
        nan = !values.f_nan
        foreach var_name, var_names, ii do begin
            if strlowcase(var_name) eq 'sopapenergy' then stop
            var_index = where(tag_names eq var_name)
            var_info = var.(var_index).att
            data = *var.(var_index).value
            if stagexist('VALID_MIN',var_info) then begin
                min_value = var_info.valid_min
                index = where(data lt min_value, count)
                if count ne 0 then data[index] = nan
            endif
            if stagexist('VALID_MAX',var_info) then begin
                max_value = var_info.valid_max
                index = where(data gt max_value, count)
                if count ne 0 then data[index] = nan
            endif
            if stagexist('FILL_VALUE',var_info) then begin
                fill_value = var_info.fill_value
                index = where(data eq fill_value, count)
                if count ne 0 then data[index] = nan
            endif
            *var.(var_index).value = data
        endforeach
    endif

    return, {__name: 'lanl_txt', $
        header: {__name: 'lanl_txt.header'}, $
        gatt: gatt, $
        var: var}

end


pro lanl_convert_txt_to_cdf, file, txt_file=txt_file, cdf_file=cdf_file, errmsg=errmsg

    errmsg = ''

    if n_elements(file) eq 0 then begin
        if n_elements(txt_file) ne 0 then file=txt_file
        if n_elements(cdf_file) ne 0 then file=cdf_file
    endif

    if n_elements(file) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return
    endif

    ; Determine the input and output files (smartly).
    pos = strpos(file, '.', /reverse_search)
    if pos eq -1 then base_name = file else base_name = strmid(file,0,pos)
    in_file = base_name+'.txt'
    out_file = base_name+'.cdf'
    ; Overwrite with given settings.
    if n_elements(txt_file) ne 0 then in_file = txt_file
    if n_elements(cdf_file) ne 0 then out_file = cdf_file

    ; Done if the conversion has been done.
    if file_test(out_file) eq 1 then return

    lanl = lanl_read_txt_data(in_file, errmsg=errmsg)
    if errmsg ne '' then begin
        errmsg = handle_error('Error in reading txt file: '+in_file+' ...')
        return
    endif

;---Save data to CDF.
    ; GLobal attribute.
    gatt = dictionary(lanl.gatt, /extract)
    gatt.remove, 'NATTS'
    scdfwrite, out_file, gattribute=gatt.tostruct()

    ; Variables.
    var_names = tag_names(lanl.var)
    foreach var_name, var_names, ii do begin
        tinfo = lanl.var.(ii)
        if size(tinfo,/type) ne 8 then continue ; should be a structure.
        vname = tinfo.name
        dims = tinfo.dims
        vatt = dictionary(tinfo.att,/extract)
        foreach key, vatt.keys() do begin
            value = vatt[key]
            if n_elements(value) gt 1 then begin
                case size(value[0],/type) of
                    7: value = strjoin(value, ',')
                    else: stop  ; don't know what to do for numbers, but there is no number for now...
                endcase
                vatt[key] = value
            endif
        endforeach
        vatt = vatt.tostruct()
        
        case n_elements(dims) of
            1: scdfwrite, out_file, vname, value=*tinfo.value, attribute=vatt
            2: scdfwrite, out_file, vname, value=transpose(*tinfo.value), attribute=vatt, dimensions=dims[1], dimvary=[1]
            else: stop  ; shouldn't reach here.
        endcase
    endforeach

end

file = '/Users/shengtian/Downloads/2019-04-09 Sheng Tian/20140828_LANL-97A_SOPA_ESP_v2.1.0.txt'
lanl_convert_txt_to_cdf, file, errmsg=errmsg
if errmsg ne '' then lprmsg, errmsg
end
