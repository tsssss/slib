;+
; Read RBSP keV electron flux.
; Save as rbspx_kev_ele_flux.
;
; set pitch_angle to load data for a specific pitch angle, otherwise load all pitch angles.
;-
function rbsp_read_kev_electron, input_time_range, probe=probe, $
    errmsg=errmsg, pitch_angle=pitch_angle, energy=energy, spec=spec

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    time_range = time_double(input_time_range)
    files = rbsp_load_mageis(time_range, probe=probe, errmsg=errmsg, id='l3')
    if errmsg ne '' then return, ''


;---Read data.
    var_list = list()
    in_vars = ['FEDU']
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''

    var = prefix+'kev_e_flux'
    enbins = cdf_read_var('FEDU_Energy', filename=files[0])
    nenbin = n_elements(enbins)
    enidx = where(finite(enbins) and enbins ge 0, nenbin)
    enbins = enbins[enidx]

    get_data, 'FEDU', uts, dat
    dat = reform(dat[*,enidx,*])>1

    ; apply energy range.
    if n_elements(energy) eq 0 then enidx = findgen(nenbin) else begin
        case n_elements(energy) of
            1: begin
                enidx = where(enbins eq energy, cnt)
                if cnt eq 0 then tmp = min(enbins-energy[0], /absolute, enidx)
                end
            2: begin
                enidx = where(enbins ge energy[0] and enbins le energy[1], cnt)
                if cnt eq 0 then begin
                    errmsg = 'no energy in given range ...'
                    return, ''
                endif
                end
            else: begin
                errmsg = 'wrong # of energy info ...'
                return, ''
                end
        endcase
    endelse
    dat = dat[*,enidx,*]
    enbins = enbins[enidx]
    nenbin = n_elements(enbins)


    ; filter pitch angle.
    pabins = cdf_read_var('FEDU_Alpha', filename=files[0])
    npabin = n_elements(pabins)
    if n_elements(pitch_angle) eq 0 then paidx = findgen(npabin) else begin
        case n_elements(pitch_angle) of
            1: begin
                paidx = where(pabins eq pitch_angle, cnt)
                if cnt eq 0 then tmp = min(pabins-pitch_angle[0], /absolute, paidx)
                end
            2: begin
                paidx = where(pabins ge pitch_angle[0] and pabins le pitch_angle[1], cnt)
                if cnt eq 0 then begin
                    errmsg = 'no pitch angle in given range ...'
                    return, ''
                endif
                end
            else: begin
                errmsg = 'wrong # of pitch angle info ...'
                return, ''
                end
        endcase
    endelse
    dat = reform(dat[*,*,paidx])
    pabins = pabins[paidx]
    npabin = n_elements(pabins)

    ; Average pitch angle if no pitch angle info is provided.
    if n_elements(pitch_angle) eq 0 then begin
        dat = total(dat,3,/nan)/npabin
        npabin = 0
    endif

    ; save data.
    if nenbin eq 1 and npabin eq 1 then begin
        store_data, var, uts, dat
        add_setting, var, /smart, {$
            display_type: 'scalar', $
            ylog: 1, $
            unit: '#/cm!U2!N-s-sr-keV', $
            short_name: 'e!U-!N flux '+sgnum2str(sround(pabins))+'deg, '+sgnum2str(sround(enbins))+'keV'}
    endif else if nenbin eq 1 then begin    ; flux vs pitch angle at certain energy.
        store_data, var, uts, dat, pabins
        add_setting, var, /smart, {$
            display_type: 'list', $
            ylog: 1, $
            unit: '#/cm!U2!N-s-sr-keV', $
            value_unit: 'deg', $
            short_name: 'e!U-!N flux '+sgnum2str(sround(enbins))+' keV'}
    endif else if npabin eq 1 then begin    ; flux vs energy at certain pitch angle.
        yrange = 10d^ceil(alog10(minmax(dat)))>1
        store_data, var, uts, dat, enbins
        add_setting, var, /smart, {$
            display_type: 'list', $
            ylog: 1, $
            yrange: yrange, $
            color_table: 52, $
            unit: '#/cm!U2!N-s-sr-keV', $
            value_unit: 'keV', $
            short_name: 'e!U-!N flux '+sgnum2str(sround(pabins))+' deg'}
    endif else begin
        store_data, var, uts, dat, enbins
        add_setting, var, /smart, {$
            display_type: 'list', $
            ylog: 1, $
            color_table: 52, $
            unit: '#/cm!U2!N-s-sr-keV', $
            value_unit: 'keV', $
            short_name: 'e!U-!N flux' }
    endelse


    if keyword_set(spec) then begin
        options, var, 'spec', 1
        options, var, 'no_interp', 1
        options, var, 'zlog', 1
        options, var, 'ylog', 1
        options, var, 'ytitle', 'Energy (keV)'
        options, var, 'ztitle', 'e!U-!N flux (#/cm!U2!N-s-sr-keV)'
        if n_elements(enbins) ne 0 then begin
            ylim, var, min(enbins), max(enbins)
        endif
    endif

;    dt = 10.848
;    uniform_time, var, dt
    return, var

end

time_range = time_double(['2014-08-28/09:30','2014-08-28/11:00'])
var = rbsp_read_kev_electron(time_range, probe='b', spec=1)
end
