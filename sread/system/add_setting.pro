;+
; Add settings to a given var.
; 
; var. A string of variable name.
; settings=. A structure of {key:value} pairs.
; smart=. A boolean to turn on smart settings. Usually set smart only once.
; id=.'efield','bfield','pflux','velocity','quaternion','dis'
;-

pro add_setting, var, settings, smart=smart, id=id, errmsg=errmsg
    
    errmsg = ''
    
    if tnames(var) eq '' then begin
        errmsg = 'No input var ...'
        return
    endif
    
    ; style settings.
    options, var, 'ynozero', 1
    options, var, 'labflag', -1
    options, var, 'ystyle', 1
    options, var, 'xticklen', -0.02
    options, var, 'yticklen', -0.01
    
    ; Try to get id from settings.
    if n_elements(id) eq 0 then begin
        if size(settings,type=1) eq 11 then begin
            if settings.haskey('id') then id = settings['id']
        endif
    endif
    if n_elements(id) ne 0 then smart = 1
    if n_elements(settings) eq 0 and keyword_set(smart) eq 0 then begin
        errmsg = 'No input settings ...'
        return
    endif
    
    if n_elements(settings) eq 0 then begin
        settings = dictionary()
    endif else begin
        if size(settings, /type) eq 8 then settings = dictionary(settings)
        foreach key, settings.keys() do options, var, key, settings[key]
    endelse
;    keys = strlowcase(tag_names(settings))
;    for i=0, n_elements(keys)-1 do options, var, keys[i], settings.(i)

    
    ; do smart things.
    if n_elements(id) eq 0 and not keyword_set(smart) then return
    ;if not keyword_set(smart) then return
    if n_elements(id) ne 0 then begin
        default_settings = dictionary()
        if id eq 'efield' then begin
            default_settings = dictionary($
                'display_type', 'vector', $
                'short_name', 'E', $
                'unit', 'mV/m' )
        endif else if id eq 'bfield' then begin
            default_settings = dictionary($
                'display_type', 'vector', $
                'short_name', 'B', $
                'unit', 'nT' )
        endif else if id eq 'pflux' then begin
            default_settings = dictionary($
                'display_type', 'vector', $
                'short_name', 'S', $
                'unit', 'mW/m!U2!N' )
        endif else if id eq 'velocity' then begin
            default_settings = dictionary($
                'display_type', 'vector', $
                'short_name', 'U', $
                'unit', 'km/s' )
        endif else if id eq 'position' then begin
            default_settings = dictionary($
                'display_type', 'vector', $
                'short_name', 'R', $
                'unit', 'Re' )            
        endif else if id eq 'quaternion' then begin
            default_settings = dictionary($
                'display_type', 'quaternion', $
                'short_name', 'Q', $
                'unit', '#', $
                'colors', sgcolor(['red','green','blue','black']), $
                'coord_labels', ['a','b','c','d'])
        endif else if id eq 'dis' then begin
            default_settings = dictionary($
                'display_type', 'scalar', $
                'short_name', '|R|', $
                'unit', 'Re' )
        endif
        
        if n_elements(default_settings) ne 0 then begin
            foreach key, default_settings.keys() do begin
                if ~settings.haskey(key) then options, var, key, default_settings[key]
            endforeach
        endif
    endif
    
    
    ; use display type to init labels.
    dtype = get_setting(var, 'display_type', exist)
    ; Try to guess
    if ~exist then begin
        get_data, var, times, data, val
        ntime = n_elements(times)
        dims = size(data, dimensions=1)
        ndim = size(data, n_dimensions=1)
        nval = n_elements(val)
        dtype = ''
        if ndim eq 1 then begin
            if ntime eq dims[0] then begin
                dtype = 'scalar'
            endif
        endif else if ndim gt 2 then begin
            errmsg = handle_error('Unknown display type ...')
            return
        endif else if dims[1] eq 3 then begin
            dtype = 'vector'
        endif else if dims[1] eq nval then begin
            dtype = 'spec'
        endif else if product(dims) eq nval then begin
            dtype = 'spec'
        endif else dtype = ''
    endif

    case dtype of
        ; data is just a work-around to saved data, usually high-dimension
        ; data that are not easy to display directly.
        'data': begin
            ; do nothing.
            end
        ; stack is less complicated than vector. The components are
        ; just the same quantity from several sources.
        'stack': begin
            options, var, 'spec', 0   
            ytitle = get_setting(var, 'ytitle', exist)
            if not exist then begin
                ; use unit to init ytitle.
                unit = get_setting(var, 'unit', exist)
                if exist then options, var, 'ytitle', '('+unit+')'
                options, var, 'ysubtitle', ''
            endif
            
            colors = get_setting(var, 'colors', exist)
            if not exist then begin
                labels = get_setting(var, 'labels', exist)
                if exist then begin
                    nval = n_elements(labels)
                    bottom = 100d
                    top = 250d
                    colors = reverse(long(smkarthm(bottom, top, nval, 'n')))
                    color_table = get_setting(var, 'color_table', exist)
                    if exist then for ii=0, nval-1 do colors[ii] = sgcolor(colors[ii], ct=color_table)
                    options, var, 'colors', colors
                endif
            endif                                
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
            
            labels = get_setting(var, 'labels', exist)
            if not exist or (exist and n_elements(labels) ne n_elements(vals)) then begin
                if size(vals[0],/type) ne 7 then begin
                    value_unit = get_setting(var, 'value_unit', exist)
                    if not exist then value_unit = ''
                    labels = strarr(nval)
                    for i=0, nval-1 do labels[i] = sgnum2str(sround(vals[i]))+' '+value_unit
                endif else labels = vals
            endif
            
            if settings.haskey('color_table') then begin
                bottom = 100d
                top = 250d
                colors = reverse(long(smkarthm(bottom, top, nval, 'n')))
                color_table = get_setting(var, 'color_table', exist)
                if exist then for ii=0, nval-1 do colors[ii] = sgcolor(colors[ii], ct=color_table)
                options, var, 'colors', colors
            endif
            colors = get_setting(var, 'colors', exist)
            if not exist or (exist and n_elements(colors) ne n_elements(vals)) then begin
                bottom = 100d
                top = 250d
                colors = reverse(long(smkarthm(bottom, top, nval, 'n')))
                color_table = get_setting(var, 'color_table', exist)
                if exist then for ii=0, nval-1 do colors[ii] = sgcolor(colors[ii], ct=color_table)
            endif
            
            options, var, 'labels', labels
            options, var, 'colors', colors
            end
        'spec': begin
            options, var, 'spec', 1
            options, var, 'no_interp', 1
            options, var, 'zcharsize', 0.8
            ;options, var, 'ylog', 1
            ;options, var, 'zlog', 1
            
            ; use unit to init ztitle.
            unit = get_setting(var, 'unit', exist)
            short_name = get_setting(var, 'short_name', exist)
            if exist then options, var, 'ztitle', strtrim(short_name+' ('+unit+')',2)
            end
        'vector': begin
            options, var, 'spec', 0
            tname = get_setting(var, 'short_name')
            coord = get_setting(var, 'coord')
            clabels = get_setting(var, 'coord_labels')
            if n_elements(clabels) ne 3 then clabels = constant('xyz')
            if n_elements(coord) eq 0 then begin
                options, var, 'labels', clabels
            endif else begin
                if n_elements(tname) eq 0 then tname = 'X'
                options, var, 'labels', strupcase(coord)+' '+tname+'!D'+clabels+'!N'
            endelse
            
            ; use unit to init ytitle.
            unit = get_setting(var, 'unit', exist)
            if exist then options, var, 'ytitle', '('+unit+')'
            options, var, 'ysubtitle', ''
            
            ; assume rgb.
            colors = get_setting(var, 'colors', exist)
            if ~exist and n_elements(clabels) eq 3 then begin
                options, var, 'colors', sgcolor(['red','green','blue'])
            endif
            end
        'quaternion': begin
            options, var, 'spec', 0
            tname = get_setting(var, 'short_name')
            coord = get_setting(var, 'coord')
            clabels = get_setting(var, 'coord_labels')
            if n_elements(clabels) ne 4 then clabels = letters(4)
            if n_elements(coord) eq 0 then begin
                options, var, 'labels', clabels
            endif else begin
                if n_elements(tname) eq 0 then tname = 'X'
                options, var, 'labels', strupcase(coord)+' '+tname+'!D'+clabels+'!N'
            endelse

            ; use unit to init ytitle.
            unit = get_setting(var, 'unit', exist)
            if exist then options, var, 'ytitle', '('+unit+')'
            options, var, 'ysubtitle', ''

            ; assume rgb.
            colors = get_setting(var, 'colors', exist)
            if ~exist and n_elements(clabels) eq 4 then begin
                options, var, 'colors', sgcolor(['red','green','blue','black'])
            endif
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
        else: ; Do nothing.
    endcase

end
