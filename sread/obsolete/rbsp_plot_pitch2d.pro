;+
; Plot 2D pitch angle distribution for a given species.
; To replace plot_hope_l3_pitch2d.
;-

function rbsp_plot_pitch2d, input_time_range, probe=probe, $
    species=input_species, unit=unit, log=log, zrange=input_zrange, $
    plot_dir=plot_dir, errmsg=errmsg, use_contour=use_contour

test = 1

;---Input check.
    prefix = 'rbsp'+probe+'_'
    retval = ''
    errmsg = ''

    if n_elements(input_species) eq 0 then input_species = 'p'
    if n_elements(unit) eq 0 then unit = 'energy'
    supported_units = ['energy','velocity']
    index = where(supported_units eq unit, count)
    if count eq 0 then begin
        errmsg = 'Invalid unit: '+unit+' ...'
        return, retval
    endif

    species = strlowcase(strmid(input_species,0,1))
    if species eq 'h' then species = strmid(input_species,0,2)
    supported_species = rbsp_hope_species()
    index = where(supported_species eq species, count)
    if count eq 0 then begin
        errmsg = 'Invalid species: '+input_species+' ...'
        return, retval
    endif



;---Settings.
    ; suppress math excepttype.
    !except = 0

    npxl = 5
    rad = !dpi/180d
    deg = 180d/!dpi

    case species of
        'e':zrange = [4,8]
        'p':zrange = [3.5,6]
        'o':zrange = [3,6]
        'he':zrange = [2,5]
    endcase
    if n_elements(input_zrange) ne 0 then zrange = input_zrange

    case species of
        'e': mass0 = 1d/1836
        'p': mass0 = 1d
        'o': mass0 = 16d
        'he': mass0 = 4d
    endcase
    mass0 = mass0*(1.67e-27/1.6e-19)   ; E in eV, mass in kg.

    species_str = rbsp_hope_species_name(species)

;---Read data.
    time_range = time_double(input_time_range)
    files = rbsp_load_hope(time_range, id='l3%pa', probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()
    suffix = (species eq 'e')? '_Ele': '_Ion'
    time_var = 'Epoch'+suffix
    energy_var = 'HOPE_ENERGY'+suffix
    flux_var = strupcase('f'+species+'du')
    dtime_var = time_var+'_DELTA'
    var_list.add, dictionary($
        'in_vars', [energy_var,flux_var,dtime_var], $
        'time_var_name', time_var, $
        'time_var_type', 'Epoch' )

    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval



;---Generate plot.
    if n_elements(plot_dir) eq 0 then begin
        plot_dir = join_path([homedir(),'rbsp_pitch2d',time_string(time_range[0],tformat='YYYY_MMDD'),'rbsp'+probe,species])
    endif
    if file_test(plot_dir) eq 0 then file_mkdir, plot_dir

    fillval = !values.f_nan
    get_data, flux_var, times, fluxs
    index = where(abs(fluxs) ge 1e30, count)
    if count ne 0 then fluxs[index] = fillval
    pitch_angles = cdf_read_var('PITCH_ANGLE', filename=files[0])
    dtimes = get_var_data(dtime_var)*1e-3
    energys = get_var_data(energy_var)

    foreach time, times, time_id do begin
        print, 'rbsp'+probe+', '+species+', '+time_string(time)

        enl3s = reform(energys[time_id,*])
        datl3 = reform(fluxs[time_id,*,*])
        pal3s = pitch_angles
        npal3 = n_elements(pal3s)

        ; Remove invalid data.
        idx = where(datl3 eq -1e31, cnt)
        if cnt ne 0 then datl3[idx] = !values.d_nan
        idx = where(datl3 eq 0, cnt)
        if cnt ne 0 then datl3[idx] = !values.d_nan

        ; Remove duplicated energy bins.
        idx = uniq(enl3s,sort(enl3s))
        enl3s = enl3s[idx]
        nenl3 = n_elements(enl3s)
        datl3 = datl3[idx,*]

        ; the data for polar contour.
        case unit of
            'energy': begin
                tdis = enl3s
                xtitle = 'E (eV)'
                end
            'velocity': begin
                tdis = sqrt(2*enl3s/mass0)*1e-3
                xtitle = 'V (km/s)'
                end
        endcase
        if keyword_set(log) then begin
            tdis = alog10(tdis)
            xtitle = 'Log!D10!N '+xtitle
        endif

        if keyword_set(use_contour) then begin
            tdat = transpose([[datl3],[datl3]])     ; in [2*npa,nen].
            tang = [pal3s,360-pal3s]
            tang = tang # ((bytarr(nenl3)+1)+smkarthm(0,0.001,nenl3,'n'))
            tang = tang*rad
            tdis = tdis ## (bytarr(2*npal3)+1)
        endif else begin
            tdat = transpose([[datl3]])     ; in [npa,nen].
            tang = [pal3s]
            tang = tang*rad
            ndis = n_elements(tdis)
            cangs = [0,9,27,45,63,81,99,117,135,153,171,180]*rad
            cdiss = 0.5*(tdis[0:ndis-2]+tdis[1:ndis-1])
            cdiss = [cdiss[0]*2-cdiss[1],cdiss,cdiss[ndis-2]*2-cdiss[ndis-3]]
        endelse


        ; remove nan.
        idx = where(finite(tdat,/nan))
        tdat[idx] = 0


        idx = where(tdat ne 0)
        min0 = min(tdat[idx],/nan)
        max0 = max(tdat[idx],/nan)
        nztick = 10
        if n_elements(zrange) eq 0 then zrange = [floor(alog10(min0)),ceil(alog10(max0))-2]
        tpos = [0.15,0.15,0.85,0.85]
        dtime = dtimes[time_id]
        title = 'RBSP-'+strupcase(probe)+' Pitch Angle, '+species_str+' flux!C'+$
            time_string(time-dtime)+' - '+time_string(time+dtime,tformat='hh:mm:ss')

        plot_type = keyword_set(polygon)? 'polygon': 'contour'
        base = prefix+'hope_l3_pitch2d_'+species+'_'+time_string(time,tformat='YYYY_MMDD_hhmm_ss')+'_'+plot_type+'_v01.pdf'
        ofn = join_path([plot_dir,base])
        if keyword_set(test) then ofn = 0
        sgopen, ofn, xsize = 5, ysize = 5, /inch
        if keyword_set(use_contour) then begin
;            sgindexcolor, 43, file = 'ct2'
;            sgdistr2d, tdat, tang, tdis, position=tpos, zrange=zrange, $
;                title=title, xtitle=xtitle, ncolor=10
            tmp = plot_pa_contour2d(tdat,tang,tdis, position=tpos, zrange=zrange, title=title, xtitle=xtitle, ncolor=10)
        endif else begin
            sgtruecolor
            sgdistr2d_polygon, tdat, tang, tdis, cangs, cdiss, position=tpos, $
                zrange=zrange, title=title, xtitle=xtitle, ncolor=10
        endelse
        if keyword_set(test) then stop
        sgclose
    endforeach

    return, retval



end


time_range = ['2013-06-01/02:00','2013-06-01/08:00']
time_range = ['2013-06-01/05:49','2013-06-01/06:00']
probe = 'a'
the_species = ['o']

time_range = ['2013-05-01/07:38','2013-05-01/07:50']
probe = 'b'
the_species = ['p','o']

foreach species, the_species do begin
    var = rbsp_plot_pitch2d(time_range, probe=probe, species=species, log=0, use_contour=1, unit='velocity')
endforeach
end