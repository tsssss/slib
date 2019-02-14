;+
; Read Themis ASI calibration file for a site.
; 
; Use this program to encapsulate the details in dealing with different
; versions of calibration files.
; 
; This program uses themis_read_asi but logically is in the same level
; of dealing with file details.
; 
; Currently only supports asf v01 and v02.
; 
; time. A time or time range in UT sec.
; vars. A string, e.g., ['mlat','mlon','glat','glon','elev'].
; site. A string for site name.
; height. A number of assumed emission altitude in km.
; version. A string, e.g., 'v01','v02'.
;-
;
pro themis_read_asc, time, vars=vars, id=id, site=site, errmsg=errmsg, $
    height=height, version=version

    compile_opt idl2
    on_error, 0
    errmsg = ''

    if n_elements(vars) eq 0 then begin
        errmsg = handle_error('No input variable ...')
        return
    endif
    if n_elements(type) eq 0 then type = 'asf'
    if n_elements(version) eq 0 then version = 'v01'
    if n_elements(id) eq 0 then id = strjoin([type,version],'%')
    if n_elements(id) ne 0 then begin
        tmp = strlowcase(strsplit(id,'%', /extract))
        type = tmp[0]
        version = tmp[1]
    endif

;---Prepare the variable names.
    pre0 = 'thg_'
    pre1 = 'thg_'+type+'_'+site+'_'
    pre2 = 'thg_'+site+'_'+type+'_'
    pre3 = 'thg_'+site+'_'

    case version of
        'v01': tvars = ['time',vars]
        'v02': tvars = ['alti',vars]
    endcase
    in_vars = pre1+tvars
    out_vars = pre2+tvars
    themis_read_asi, time, id='asc', site=site, errmsg=errmsg, $
        in_vars=in_vars, out_vars=out_vars, version=version, skip_index=1
    time_var = pre2+'time'
    alti_var = pre2+'alti'
    if n_elements(height) eq 0 then height = 110d   ; km.


;---Now treat the calibration files.
    pos_vars = pre3+'asf_'+['elev','azim']
    foreach pos_var, pos_vars do begin
        index = where(out_vars eq pos_var, count)
        if count eq 0 then continue
        case version of
            'v01': begin
            ;---For calibration files of version 01.
                get_data, pos_var, tmp, dat
                store_data, pos_var, time[0], reform(dat[0,*,*])
                end
            'v02': begin
            ;---For calibration files of version 02.
                times = get_var_data(time_var)
                dat = get_var_data(pos_var)
                index = where(times lt time[0], count)
                if count eq 0 then index = 0
                store_data, pos_var, time[0], reform(dat[index,*,*])
                end
        endcase
        add_setting, pos_var, /smart, {$
            display_type: 'image', $
            unit: 'deg', $
            short_name: site[0]+' '+strmid(pos_var, 0,4, /reverse)}
    endforeach


    pos_vars = pre3+'asf_'+['mlon','mlat','glon','glat']
    foreach pos_var, pos_vars do begin
        index = where(out_vars eq pos_var, count)
        if count eq 0 then continue
        case version of
            'v01': begin
                get_data, pos_var, tmp, dat
                altis = get_var_data(alti_var)*1e-3     ; in km.
                tmp = min(altis-height, /absolute, index)
                store_data, pos_var, time[0], reform(dat[0,index,*,*])
                end
            'v02': begin
                times = get_var_data(time_var)
                dat = get_var_data(pos_var)
                index = where(times lt time[0], count)
                if count eq 0 then index = 0
                store_data, pos_var, time[0], reform(dat[index,*,*])
                end
        endcase
        add_setting, pos_var, /smart, {$
            display_type: 'image', $
            unit: 'deg', $
            short_name: site[0]+' '+strmid(pos_var, 0,4, /reverse)}
    endforeach

    
end

time = time_double(['2014-08-28/09:55','2014-08-28/10:05'])
site = 'whit'
themis_read_asc, time, site=site, vars=['mlon','mlat'], id='asf%v01'
end
