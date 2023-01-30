;+
; Plot 2D pitch angle distribution for a given species.
; To replace plot_hope_l3_pitch2d and rbsp_plot_pitch2d.
; 
; input_time_range. start and end times in string or unix time.
; probe=. 'a' or 'b'.
; contour=. Boolean, set to use contour, default is polygon.
; file_suffix=. Default is '', to add suffix to filenames.
; species=. ['e','p','o','he'].
; unit=. ['energy','velocity'].
; log=. A boolean to set log scale. Default is linear.
; zrange=. To set zrange for the colorbar.
; plot_dir=. The directory to save the plots. Default is in homedir.
;-

function energy_scale_func, energys

    energy0 = 2e4   ; 1 keV.
    scaled_energys = (tanh(energys/energy0))^0.25
    scaled_energys = energys^0.25
    return, scaled_energys
    
end


function rbsp_plot_pa_contour2d, input_time_range, probe=probe, $
    contour=contour, test=test, file_suffix=file_suffix, $
    species=input_species, unit=unit, log=log, zrange=input_zrange, $
    plot_dir=plot_dir, errmsg=errmsg, position=the_pos

test = 1


;---Input check.
    prefix = 'rbsp'+probe+'_'
    retval = ''
    errmsg = ''

    if n_elements(input_species) eq 0 then input_species = 'p'
    if n_elements(unit) eq 0 then unit = 'energy'
    supported_units = ['energy','velocity','scaled_energy']
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

    if n_elements(file_suffix) eq 0 then file_suffix = ''

;---Settings.
    ; suppress math excepttype.
    !except = 0

    rad = !dpi/180d
    deg = 180d/!dpi

    the_pos = panel_pos(0, pansize=[1,1]*2, margins=[10,4,8,3], fig_size=fig_size)
    

    case species of
        'e':log_zrange = [4,8]
        'p':log_zrange = [4,6]
        'o':log_zrange = [3,6]
        'he':log_zrange = [2,5]
    endcase
    zrange = 10.^log_zrange
    if n_elements(input_zrange) ne 0 then zrange = input_zrange
    ncolor = 15

    case species of
        'e': mass0 = 1d/1836
        'p': mass0 = 1d
        'o': mass0 = 16d
        'he': mass0 = 4d
    endcase
    mass0 = mass0*(1.67e-27/1.6e-19)   ; E in eV, mass in kg.
    
    case species of
        'e': default_ct = 62
        'p': default_ct = 63
        'o': default_ct = 64
        'he': default_ct = 60
    endcase
    if n_elements(color_table) eq 0 then color_table = default_ct


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
    npitch_angle = n_elements(pitch_angles)
    dtimes = get_var_data(dtime_var)*1e-3
    energys = get_var_data(energy_var)

    foreach time, times, time_id do begin
        print, 'rbsp'+probe+', '+species+', '+time_string(time)

        this_energys = reform(energys[time_id,*])
        this_fluxs = reform(fluxs[time_id,*,*])

        ; Remove duplicated energy bins.
        index = uniq(this_energys,sort(this_energys))
        this_energys = this_energys[index]
        nenergy = n_elements(this_energys)
        this_fluxs = this_fluxs[index,*]
        
        energy_range = minmax(this_energys)
        energy_range = [ceil(energy_range[0]),floor(energy_range[1])]
        energy_circles = smkgmtrc(energy_range[0],energy_range[1],10,'dx')

        ; the data for polar contour.
        case unit of
            'energy': begin
                this_diss = this_energys
                axis_title = 'E (eV)'
                circles = energy_circles
                xrange = [-1,1]*max(this_diss)
                end
            'velocity': begin
                this_diss = sqrt(2*this_energys/mass0)*1e-3
                axis_title = 'V (km/s)'
                circles = sqrt(2*energy_circles/mass0)*1e-3
                xrange = [-1,1]*max(this_diss)
                end
            'scaled_energy': begin
                this_diss = energy_scale_func(this_energys)
                axis_title = 'E (eV)'
                circles = energy_scale_func(energy_circles)
                xrange = [-1,1]*max(this_diss)
            end
        endcase
        flux_unit = 'Log!D10!N flux (#/s-cm!E2!N-sr-eV)'
        ztitle = species_str+' '+flux_unit


        if ~keyword_set(contour) then begin
            nangle = npitch_angle*2-2
            dangle = 360/nangle
            angles = smkarthm(0,360-dangle,dangle,'dx')
            
            the_angles = fltarr(nangle,nenergy,2)
            the_angles[*,*,0] = (angles-dangle*0.5) # (bytarr(nenergy)+1)
            the_angles[*,*,1] = (angles+dangle*0.5) # (bytarr(nenergy)+1)
            
            the_fluxs = transpose([[this_fluxs],[reverse(this_fluxs[*,1:-2],2)]])     ; in [2*npa,nen].            
            
            the_diss = fltarr(nangle,nenergy,2)
            for ii=0,nenergy-1 do begin
                if ii eq 0 then begin
                    the_diss[*,ii,1] = sqrt(this_diss[ii]*this_diss[ii+1])
                    the_diss[*,ii,0] = this_diss[ii]^2
                    the_diss[*,ii,0] /= the_diss[*,ii,1]
                endif else if ii eq nenergy-1 then begin
                    the_diss[*,ii,0] = sqrt(this_diss[ii-1]*this_diss[ii])
                    the_diss[*,ii,1] = this_diss[ii]^2
                    the_diss[*,ii,1] /= the_diss[*,ii,0]
                endif else begin
                    the_diss[*,ii,0] = sqrt(this_diss[ii-1]*this_diss[ii])
                    the_diss[*,ii,1] = sqrt(this_diss[ii]*this_diss[ii+1])
                endelse
            endfor
        endif else begin
;            nangle = 2*npitch_angle
;            ; Need to be slightly different to avoid contour breaks
;            the_angles = [pitch_angles,reverse(360-pitch_angles)]
;            the_angles = the_angles # ((bytarr(nenergy)+1)+smkarthm(0,0.001,nenergy,'n'))
;            the_diss = this_diss ## (bytarr(nangle)+1)
;            the_fluxs = transpose([[this_fluxs],[reverse(this_fluxs,2)]])     ; in [2*npa,nen].
            nangle = 2*npitch_angle-2
            dangle = 360/nangle
            angles = smkarthm(0,360-dangle,dangle,'dx')
            
            ; Need to be slightly different to avoid contour breaks
            the_angles = angles # ((bytarr(nenergy)+1)+smkarthm(0,0.001,nenergy,'n'))
            the_diss = this_diss ## (bytarr(nangle)+1)
            the_fluxs = transpose([[this_fluxs],[reverse(this_fluxs[*,1:-2],2)]])     ; in [2*npa,nen].
        endelse
        the_angles = the_angles*rad
        
        
        if keyword_set(log) then begin
            the_diss = alog10(the_diss)
            xrange = [-1,1]*alog10(abs(xrange[1]))
            circles = alog10(circles)
            axis_title = 'Log!D10!N '+axis_title
        endif
        

        ; Remove nan and invalid data.
        index = where(the_fluxs eq -1e31, count)
        if count ne 0 then the_fluxs[index] = 0
        index = where(finite(the_fluxs,nan=1), count)
        if count ne 0 then the_fluxs[index] = 0

        dtime = dtimes[time_id]
        title = 'RBSP-'+strupcase(probe)+' '+$
            time_string(time-dtime)+' - '+time_string(time+dtime,tformat='hh:mm:ss')

        base = prefix+'hope_l3_pitch2d_'+species+'_'+time_string(time,tformat='YYYY_MMDD_hhmm_ss')+file_suffix+'_v01.pdf'
        ofn = join_path([plot_dir,base])
        if keyword_set(test) then ofn = 0
        sgopen, ofn, size=fig_size, inch=1
        if ~keyword_set(contour) then begin
            tmp = plot_pa_contour2d_polygon(the_fluxs,the_angles,the_diss,$
                position=the_pos, zrange=zrange, title=title, $
                axis_title=axis_title, ncolor=ncolor, color_table=color_table, $
                circles=circles, xrange=xrange, ztitle=ztitle)
        endif else begin
            tmp = plot_pa_contour2d(the_fluxs,the_angles,the_diss,$
                position=the_pos, zrange=zrange, title=title, $
                axis_title=axis_title, ncolor=ncolor, color_table=color_table, $
                circles=circles, xrange=xrange, ztitle=ztitle)
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

time_range = ['2013-05-01/07:38','2013-05-01/07:45']
probe = 'b'
the_species = ['o','p']

foreach species, the_species do begin
    var = rbsp_plot_pa_contour2d(time_range, probe=probe, species=species, log=0, unit='scaled_energy', zrange=[5e3,5e5])
endforeach
end