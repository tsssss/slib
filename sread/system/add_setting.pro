;+
; Add settings to a given var.
; 
; var. A string of variable name.
; settings. A structure of {key:value} pairs.
; smart. A boolean to turn on smart settings. Usually set smart only once.
;-

pro add_setting, var, settings, smart=smart
    
    if tnames(var) eq '' then return
    
    keys = strlowcase(tag_names(settings))
    for i=0, n_elements(keys)-1 do options, var, keys[i], settings.(i)
        
    ; style settings.
    options, var, 'ynozero', 1
    options, var, 'labflag', -1
    options, var, 'ystyle', 1
    options, var, 'xticklen', -0.02
    options, var, 'yticklen', -0.01
    
    ; do smart things.
    if not keyword_set(smart) then return

    ; use display type to init labels.
    dtype = get_setting(var, 'display_type', exist)
    if exist then begin
        case dtype of
            ; data is just a work-around to saved data, usually high-dimension
            ; data that are not easy to display directly.
            'data': begin
                ; do nothing.
                end
            ; list is more complicate than vector. The components of a list
            ; are a second variable with certain unit, whereas a vector has
            ; several components, which are just labels.
            'list': begin
                options, var, 'spec', 0
                unit = get_setting(var, 'unit', exist)
                if not exist then unit = ''
                short_name = get_setting(var, 'short_name', exist)
                if not exist then short_name = ''
                options, var, 'ytitle', short_name+'!C('+unit+')'
                get_data, var, uts, dat, vals
                nval = n_elements(vals)
                if size(vals[0],/type) ne 7 then begin
                    value_unit = get_setting(var, 'value_unit', exist)
                    if not exist then value_unit = ''
                    labels = strarr(nval)
                    for i=0, nval-1 do labels[i] = sgnum2str(sround(vals[i]))+' '+value_unit
                endif else labels = vals
                
                bottom = 100d
                top = 250d
                colors = reverse(long(smkarthm(bottom, top, nval, 'n')))
                color_table = get_setting(var, 'color_table', exist)
                if exist then for ii=0, nval-1 do colors[ii] = sgcolor(colors[ii], ct=color_table)
                options, var, 'labels', labels
                options, var, 'colors', colors
                end
            'spec': begin
                options, var, 'spec', 1
                options, var, 'no_interp', 1
                
                ; use unit to init ztitle.
                unit = get_setting(var, 'unit', exist)
                short_name = get_setting(var, 'short_name', exist)
                if exist then options, var, 'ztitle', short_name+'('+unit+')'
                end
            'vector': begin
                options, var, 'spec', 0
                tname = get_setting(var, 'short_name')
                coord = get_setting(var, 'coord')
                clabels = get_setting(var, 'coord_labels')
                options, var, 'labels', coord+' '+tname+'!D'+clabels+'!N'
                
                ; use unit to init ytitle.
                unit = get_setting(var, 'unit', exist)
                if exist then options, var, 'ytitle', '('+unit+')'
                options, var, 'ysubtitle', ''
                end
            'scalar': begin
                options, var, 'spec', 0
                tname = get_setting(var, 'short_name')
                options, var, 'labels', tname
                
                ; use unit to init ytitle.
                unit = get_setting(var, 'unit', exist)
                if exist then options, var, 'ytitle', '('+unit+')'
                options, var, 'ysubtitle', ''
                end
            'plot': begin
                options, var, 'spec', 0
                end
            'image': begin
                ; Placeholder, do nothing.
                end
        endcase
    endif

end
