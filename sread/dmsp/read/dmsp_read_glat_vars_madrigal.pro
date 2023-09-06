;+
; Read DMSP orbit. glat, glon, alt. ssm and ssj are the same.
; glat and alt are geocentric by default, not geodetic.
; geodetic=. Set to return geodetic glat/glon/alt.
;-

function dmsp_read_glat_vars_madrigal, input_time_range, probe=probe, errmsg=errmsg, get_name=get_namem, suffix=suffix, geodetic=geodetic, _extra=ex

    prefix = 'dmsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(suffix) eq 0 then suffix = '_madrigal'
    vars = prefix+['glat','glon','alt']+suffix
    if keyword_set(get_name) then return, vars

    time_range = time_double(input_time_range)
    if ~check_if_update(vars[0], time_range) then return, vars

    files = dmsp_load_ssj_madrigal(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

;---Read data.
    glat_var = '/Data/Array Layout/1D Parameters/gdlat'
    gdlat = hdf_read_var(glat_var, filename=files)
    glon_var = '/Data/Array Layout/1D Parameters/glon'
    glon = hdf_read_var(glon_var, filename=files)
    alt_var = '/Data/Array Layout/1D Parameters/gdalt'
    gdalt = hdf_read_var(alt_var, filename=files)

    re = constant('re')
    if keyword_set(geodetic) then begin
        alt = gdalt
        glat = gdlat
    endif else begin
        alt = geod2geoc(gdalt, gdlat, glat)-re  ; convert to geocentric latitude and altitude.
    endelse


;---Calibrate the data.
    time_var = '/Data/Array Layout/timestamps'
    times = hdf_read_var(time_var, filename=files)
    time_index = where_pro(times, '[]', time_range, count=count)
    if count eq 0 then begin
        errmsg = 'No data in given time_range ...'
        return, retval
    endif
    times = times[time_index]
    glat = glat[time_index]
    glon = glon[time_index]
    alt = alt[time_index]
    
    var = vars[0]
    store_data, var, times, glat
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'deg', $
        'short_name', 'GLat' )

    var = vars[1]
    store_data, var, times, glon
    ; despike.
    time_step = 60
    times_despike = make_bins(time_range, time_step, inner=1)
    glon_despike = interpol(interpol(glon,times,times_despike), times_despike, times, quadratic=1)
;    index = where(abs(glon_despike) le 1, count)
    diff = glon-glon_despike
    index = where(abs(glon_despike) le 1, count)
    if count ne 0 then begin
        index_ranges = time_to_range(index,time_step=1)
        nrecs = index_ranges[*,1]-index_ranges[*,0]
        index = where(nrecs gt 1, count)
        if count ne 0 then begin
            index_ranges = index_ranges[index,*]
            time_ranges = times[index_ranges]
            nrange = n_elements(time_ranges[*,0])
            for ii=0,nrange-1 do begin
                the_time_range = mean(time_ranges[ii,*])+[-1,1]*time_step*1
                index = where_pro(times, '[]', the_time_range, count=count)
                if count eq 0 then continue
                glon_start = glon[index[0]]
                glon_end = glon[index[-1]]
                glon[index] = !values.f_nan
                if (glon_end-glon_start) lt 300 then continue
                ;if glon_end lt glon_start then glon[index[-1]:*] += 360 else glon[index[-1]:*] -= 360
            endfor
            index = where(finite(glon), count)
            if count eq 0 then begin
                errmsg = 'No valid data ...'
                return, retval
            endif else begin
                glon = interpol(glon[index],times[index], times, spline=1)
                store_data, var, times, glon
            endelse
        endif
    endif
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'deg', $
        'short_name', 'GLon' )
    
    var = vars[2]
    store_data, var, times, alt
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'km', $
        'short_name', 'Altitude' )


    return, vars

end


time_range = ['2013-05-01','2013-05-02']
probe = 'f16'
r1_var = dmsp_read_glat_vars_madrigal(time_range, probe=probe)
r2_var = dmsp_read_glat_vars_cdaweb(time_range, probe=probe)
end