;+
; Return unused data_vars, support_vars, and labeling_vars.
;
; file_in. A string for the CDF.
; used_vars=. Out dictionary.
;-

function cdf_detect_unused_vars, file_in, used_vars=used_vars

    if file_test(file_in) eq 0 then return, !null
    skeleton = cdf_read_skeleton(file_in)
    var_infos = skeleton.var


;---Group all vars according to the datatype.
    grouped_vars = dictionary()
    foreach var_info, var_infos do begin
        if ~var_info.haskey('setting') then begin
            var_type = 'unknown'
        endif else begin
            vatts = var_info['setting']
            if ~vatts.haskey('VAR_TYPE') then begin
                var_type = 'unknown'
            endif else begin
                var_type = vatts['VAR_TYPE']
            endelse
        endelse
        if ~grouped_vars.haskey(var_type) then begin
            grouped_vars[var_type] = list()
        endif
        grouped_vars[var_type].add, var_info.name
    endforeach


    used_vars = dictionary()
    unused_vars = dictionary()

;---Check 'data' vars.
    the_type = 'data'
    used_vars[the_type] = list()
    unused_vars[the_type] = list()
    if grouped_vars.haskey(the_type) then begin
        vars = grouped_vars[the_type]
        foreach var, vars do begin
            found_it = 0
            settings = var_infos[var]
            if settings.maxrec gt 0 then found_it = 1
            if found_it then begin
                (used_vars[the_type]).add, var
            endif else begin
                (unused_vars[the_type]).add, var
            endelse
        endforeach
    endif


;---Check 'support_data' vars.
    the_type = 'support_data'
    used_vars[the_type] = list()
    unused_vars[the_type] = list()
    search_vars = list(used_vars.data,/extract)
    if grouped_vars.haskey(the_type) then begin
        vars = grouped_vars[the_type]
        foreach var, vars do begin
            found_it = 0
            foreach data_var, search_vars do begin
                settings = var_infos[data_var].setting
                foreach key, settings.keys() do begin
                    val = settings[key]
                    if n_elements(val) ne 1 then continue
                    if size(val[0],/type) ne 7 then continue
                    if val eq var then begin
                        found_it = 1
                        break
                    endif
                endforeach
                if found_it then break
            endforeach
            if found_it then begin
                (used_vars[the_type]).add, var
            endif else begin
                (unused_vars[the_type]).add, var
            endelse
        endforeach
    endif


;---Check 'metadata' vars.
    the_type = 'metadata'
    used_vars[the_type] = list()
    unused_vars[the_type] = list()
    search_vars = list(used_vars.data,used_vars.support_data,/extract)
    if grouped_vars.haskey(the_type) then begin
        vars = grouped_vars[the_type]
        foreach var, vars do begin
            found_it = 0
            foreach data_var, used_vars.data do begin
                settings = var_infos[data_var].setting
                foreach key, settings.keys() do begin
                    val = settings[key]
                    if n_elements(val) ne 1 then continue
                    if size(val[0],/type) ne 7 then continue
                    if val eq var then begin
                        found_it = 1
                        break
                    endif
                endforeach
                if found_it then break
            endforeach
            if found_it then begin
                (used_vars[the_type]).add, var
            endif else begin
                (unused_vars[the_type]).add, var
            endelse
        endforeach
    endif

    return, unused_vars

end


file = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_vsvy-hires_20190101_v01.cdf'
file = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_esvy_despun_20170103_v02.cdf'
;file = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_e-spinfit-mgse_20140608_v02.cdf'
unused_vars = cdf_detect_unused_vars(file)
end
