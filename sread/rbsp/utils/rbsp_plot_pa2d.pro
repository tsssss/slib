;+
; Plot 2D pitch angle distribution for a given species.
; To replace plot_hope_l3_pitch2d and rbsp_plot_pitch2d.
; Related programs are plot_pa_contour2d and plot_pa_contour2d_polygon.
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


function scale_dis, dis, scale_method
    if scale_method eq 'linear' then return, dis
    if scale_method eq 'log' then return, alog10(dis)
    if scale_method eq 'default' then return, dis^0.25
    message, 'Unkown method: '+scale_method
end

function inverse_scale_dis, dis, scale_method
    if scale_method eq 'linear' then return, dis
    if scale_method eq 'log' then return, 10.^dis
    if scale_method eq 'default' then return, dis^4
    message, 'Unkown method: '+scale_method

end


function rbsp_plot_pa2d, input_time_range, probe=probe, $
    times=pa_times, pa2d_var=pa2d_var, $
    contour=contour, test=test, file_suffix=file_suffix, $
    species=input_species, unit=unit, scale_method=scale_method, zrange=input_zrange, $
    xtickv=xtickv, combine_energy_bin=combine_energy_bin, $
    plot_dir=plot_dir, errmsg=errmsg, position=tpos, $
    no_colorbar=no_colorbar, title=input_title, ztitle=ztitle, $
    xtitle=xtitle, ytitle=ytitle, $
    xtickformat=xtickformat, ytickformat=ytickformat

;test = 1


;---Input check and settings.
    prefix = 'rbsp'+probe+'_'
    retval = ''
    errmsg = ''
    time_range = time_double(input_time_range)

    ; Species related settings.
    if n_elements(input_species) eq 0 then input_species = 'p'
    species = strlowcase(strmid(input_species,0,1))
    if species eq 'h' then species = strmid(input_species,0,2)
    supported_species = rbsp_hope_species()
    index = where(supported_species eq species, count)
    if count eq 0 then begin
      errmsg = 'Invalid species: '+input_species+' ...'
      return, retval
    endif
    species_str = rbsp_hope_species_name(species)
    
    ; mass.
    case species of
      'e': mass0 = 1d/1836
      'p': mass0 = 1d
      'o': mass0 = 16d
      'he': mass0 = 4d
    endcase
    mass0 = mass0*(1.67e-27/1.6e-19)   ; E in eV, mass in kg.

    ; color table.
    case species of
      'e': default_ct = 62
      'p': default_ct = 63
      'o': default_ct = 64
      'he': default_ct = 60
    endcase
    if n_elements(color_table) eq 0 then color_table = default_ct
    
    ; zrange and log_zrange, ztitle, zlog, etc.
    case species of
      'e':log_zrange = [4,8]
      'p':log_zrange = [4,6]
      'o':log_zrange = [3,6]
      'he':log_zrange = [2,5]
    endcase
    zrange = 10.^log_zrange
    if n_elements(input_zrange) ne 0 then begin
      zrange = input_zrange
      log_zrange = alog10(zrange)
    endif
    
    zlog = 1
    flux_unit = 'Log!I10!N flux (#/s-cm!E2!N-sr-eV)'
    if n_elements(ztitle) eq 0 then ztitle = species_str+' '+flux_unit
    log_ztickv = make_bins(log_zrange,1,inner=1)
    if n_elements(ztickv) eq 0 then ztickv = 10^log_ztickv
    if n_elements(zticks) eq 0 then zticks = n_elements(ztickv)-1
    if n_elements(zminor) eq 0 then zminor = 10


    ; color settings.
    ncolor = 15
    color_top = 250
    color_bottom = 10
    if n_elements(color_table) eq 0 then color_table = 40
    index_colors = floor(smkarthm(color_bottom,color_top,ncolor,'n'))
    colors = index_colors
    for ii=0,ncolor-1 do colors[ii] = sgcolor(index_colors[ii],ct=color_table)
    log_c_levels = smkarthm(log_zrange[0],log_zrange[1],ncolor,'n')
    c_levels = 10.^log_c_levels
    
    
    ; Unit related settings.
    if n_elements(unit) eq 0 then unit = 'energy'
    supported_units = ['energy','velocity']
    index = where(supported_units eq unit, count)
    if count eq 0 then begin
        errmsg = 'Invalid unit: '+unit+' ...'
        return, retval
    endif
    axis_title = (unit eq 'velocity')? 'V (km/s)': 'E (eV)'
    
    

    ; Plot related settings.
    if ~keyword_set(gen_figure) then gen_figure = (n_elements(tpos) eq 4)? 0: 1
    if n_elements(file_suffix) eq 0 then file_suffix = ''
    if n_elements(tpos) eq 0 then begin
        tpos = panel_pos(0, pansize=[1,1]*2, margins=[10,4,8,3], fig_size=fig_size)
        sgopen, 0, size=fig_size, xchsz=xchsz, ychsz=ychsz
        sgclose, wdelete=1
    endif else begin
        xchsz = double(!d.x_ch_size)/!d.x_size
        ychsz = double(!d.y_ch_size)/!d.y_size
    endelse

    ; colorbar pos.
    if n_elements(cbpos) eq 0 then begin
        cbpos = tpos
        cbpos[0] = cbpos[2]+xchsz
        cbpos[2] = cbpos[0]+xchsz
    endif


    ; ticklen.
    abs_ticklen = -ychsz*0.15
    xticklen = abs_ticklen/(tpos[3]-tpos[1])
    yticklen = abs_ticklen/(tpos[2]-tpos[0])
    zticklen = abs_ticklen/(cbpos[2]-cbpos[0])

    if n_elements(xtitle) eq 0 then xtitle = 'Para '+axis_title
    if n_elements(ytitle) eq 0 then ytitle = 'Perp '+axis_title

    label_size = 0.8


    ; constants.
    rad = !dpi/180d
    deg = 180d/!dpi
    


    



;---Read data.
    if n_elements(pa2d_var) eq 0 then begin
        pa2d_var = rbsp_plot_pa2d_read_data(time_range, probe=probe, species=species, get_name=1)
        if tnames(pa2d_var) eq '' then begin
            pa2d_var = rbsp_plot_pa2d_read_data(time_range, probe=probe, species=species)
        endif
    endif
    combo_energys = get_setting(pa2d_var, 'combo_energys')
    pitch_angles = get_setting(pa2d_var, 'pitch_angles')
    dtimes = get_setting(pa2d_var, 'dtimes')
    get_data, pa2d_var, common_times, combo_fluxs
    nangle = n_elements(pitch_angles)
    dangle = abs(total(pitch_angles[1:2]*[-1,1]))


;---Generate plot.
    if n_elements(plot_dir) eq 0 then begin
        plot_dir = join_path([homedir(),'rbsp_pitch2d',time_string(time_range[0],tformat='YYYY_MMDD'),'rbsp'+probe,species])
    endif
    if file_test(plot_dir) eq 0 then file_mkdir, plot_dir


    if n_elements(pa_times) eq 0 then pa_times = common_times

    foreach time, pa_times, time_id do begin
        print, 'rbsp'+probe+', '+species+', '+time_string(time)

        time_id = (where(common_times eq time, count))[0]
        if count eq 0 then tmp = min(common_times-time, time_id, abs=1)
        energys = reform(combo_energys[time_id,*])
        fluxs = reform(combo_fluxs[time_id,*,*])
        dtime = dtimes[time_id]


        ; Remove duplicated energy bins.
        index = uniq(energys,sort(energys))
        energys = energys[index]
        nenergy = n_elements(energys)
        fluxs = fluxs[index,*]
        
        energy_range = minmax(energys)
        energy_range = [ceil(energy_range[0]),floor(energy_range[1])]
        log_energy_range = alog10(energy_range)
        log_energy_range = [ceil(log_energy_range[0]),floor(log_energy_range[1])]
        log_energy_circles = make_bins(log_energy_range,1, inner=1)
        energy_circles = 10.^log_energy_circles

        ; the data for polar contour.
        ; diss is the quantity for x and y.
        case unit of
            'energy': begin
                diss = energys
                circles = energy_circles
                dis_range = [-1,1]*max(diss)
                end
            'velocity': begin
                diss = sqrt(2*energys/mass0)*1e-3
                circles = sqrt(2*energy_circles/mass0)*1e-3
                dis_range = [-1,1]*max(diss)
                end
        endcase

    ;---Reshape data depend on contour or polygon.
        if ~keyword_set(contour) then begin
            the_angles = fltarr(nangle,nenergy,2)
            the_angles[*,*,0] = (pitch_angles-dangle*0.5) # (bytarr(nenergy)+1)
            the_angles[*,*,1] = (pitch_angles+dangle*0.5) # (bytarr(nenergy)+1)
            
            the_fluxs = transpose([[fluxs],[reverse(fluxs[*,1:-2],2)]])     ; in [2*npa,nen].            
            
            the_diss = fltarr(nangle,nenergy,2)
            for ii=0,nenergy-1 do begin
                if ii eq 0 then begin
                    the_diss[*,ii,1] = sqrt(diss[ii]*diss[ii+1])
                    the_diss[*,ii,0] = diss[ii]^2
                    the_diss[*,ii,0] /= the_diss[*,ii,1]
                endif else if ii eq nenergy-1 then begin
                    the_diss[*,ii,0] = sqrt(diss[ii-1]*diss[ii])
                    the_diss[*,ii,1] = diss[ii]^2
                    the_diss[*,ii,1] /= the_diss[*,ii,0]
                endif else begin
                    the_diss[*,ii,0] = sqrt(diss[ii-1]*diss[ii])
                    the_diss[*,ii,1] = sqrt(diss[ii]*diss[ii+1])
                endelse
            endfor
        endif else begin
            ; Need to be slightly different to avoid contour breaks
            the_angles = pitch_angles # ((bytarr(nenergy)+1)+smkarthm(0,0.001,nenergy,'n'))
            the_diss = diss ## (bytarr(nangle)+1)
            the_fluxs = transpose([[fluxs],[reverse(fluxs[*,1:-2],2)]])     ; in [2*npa,nen].
        endelse
        the_angles = the_angles*rad



    ;---Treat scale_method.
        if n_elements(scale_method) eq 0 then scale_method = 'default'
        scaled_diss = scale_dis(the_diss, scale_method)
        ; xrange is defined on physical quantities (velocity or energy).
        if n_elements(xrange) ne 2 then xrange = [-1,1]*max(diss)
        if total(xrange) ne 0 then xrange = [-1,1]*max(diss)
        ; scale xrange is defined on the scaled axis.
        ; scaled axis is linear on x and y.
        scaled_xrange = [-1,1]*scale_dis(xrange[1], scale_method)
        scaled_circles = scale_dis(circles, scale_method)



    ;---Start to plot.
        if gen_figure then begin
            base = prefix+'hope_l3_pitch2d_'+species+'_'+time_string(time,tformat='YYYY_MMDD_hhmm_ss')+file_suffix+'_v01.pdf'
            ofn = join_path([plot_dir,base])
            if keyword_set(test) then ofn = 0
            if keyword_set(test) then magn = 2 else magn = 1
            sgopen, ofn, size=fig_size, inch=1, magn=magn
        endif

        ; Title.
        if n_elements(input_title) eq 0 then begin
            title = 'RBSP-'+strupcase(probe)+' '+$
            time_string(time-dtime)+' - '+time_string(time+dtime,tformat='hh:mm:ss')+' UT'
        endif else title = input_title

        ; plot color bar.
        if ~keyword_set(no_colorbar) then begin
            sgcolorbar, index_colors, position=cbpos, ct=color_table, $
                zrange=zrange, ztitle=ztitle, zcharsize=label_size, log=zlog, $
                ztickv=ztickv, zticks=zticks, zminor=zminor, zticklen=zticklen, $
                _extra=ex
        endif
        

        ; plot settings.
        if n_elements(xtickv) eq 0 then begin
            if scale_method eq 'log' or scale_method eq 'default' then begin
                log_xtickv = make_bins([0,scale_dis(xrange[1],'log')],1,inner=1)
                xtickv = inverse_scale_dis(log_xtickv,'log')
                xminor = 0
            endif else begin
                xminor = 4
            endelse
        endif else begin
        endelse

        if n_elements(xtickv) ne 0 then begin
            scaled_xtickv = scale_dis(xtickv,scale_method)
            scaled_xtickv = [-scaled_xtickv,0,scaled_xtickv]
            scaled_xtickv = sort_uniq(scaled_xtickv)
            orig_xtickv = round(inverse_scale_dis(scaled_xtickv,scale_method))
            xticks = n_elements(orig_xtickv)-1
            xtickn = strarr(xticks+1)
            for ii=0,xticks do begin
                if orig_xtickv[ii] eq 0 then begin
                    xtickn[ii] = '0'
                    continue
                endif
                xtickn[ii] = string(abs(orig_xtickv[ii]),format='(I0)')
                if scale_method eq 'log' or scale_method eq 'default' then begin
                    xtickn[ii] = '10!E'+string(scale_dis(abs(orig_xtickv[ii]),'log'),format='(I0)')
                endif
                if xtickn[ii] eq '10!E0' then xtickn[ii] = '1'
                if xtickn[ii] eq '10!E1' then xtickn[ii] = '10'
                if scaled_xtickv[ii] le 0 then xtickn[ii] = '-'+xtickn[ii]
            endfor
            
            ; To remove overlapping ticknames.
            if unit eq 'energy' then begin
                index = where(orig_xtickv le 200 and orig_xtickv ge 20 or orig_xtickv le 2, count)
                if count ne 0 then xtickn[index] = ' '
            endif else if unit eq 'velocity' then begin
                if species eq 'p' then begin
                    ; 1, 100, 1000.
                    index = where(orig_xtickv le 20 and orig_xtickv ge 2 or orig_xtickv le 0.2, count)
                endif else if species eq 'o' then begin
                    ; 0, 10, 100.
                    index = where(orig_xtickv le 2 and orig_xtickv ne 0, count)
                endif else if species eq 'he' then begin
                    ; 1, 100, 1000.
                    index = where(orig_xtickv le 20 and orig_xtickv ge 2 or orig_xtickv le 0.2, count)
                endif else if species eq 'e' then begin
                    ; 10, 1e3, 1e4, 1e5.
                    index = where(orig_xtickv le 200 and orig_xtickv ge 20 or orig_xtickv le 2, count)
                endif
                if count ne 0 then xtickn[index] = ' '
            endif
        endif else begin
            orig_xtickv = !null
            xticks = !null
            xtickn = !null
        endelse
        


        if keyword_set(contour) then begin
            polar_contour, the_fluxs, the_angles, scaled_diss, noerase=1, $
                position=tpos, fill=1, iso=1, $
                nlevel=nztick, levels=c_levels, c_colors=colors, $
                xtitle=xtitle, xstyle=5, xrange=scaled_xrange, $
                ytitle=ytitle, ystyle=5, yrange=scaled_xrange, $
                xticklen=xticklen, yticklen=yticklen, $
                _extra=ex
        endif else begin
            ; Setup the coord.
            plot, scaled_xrange, scaled_xrange, noerase=1, nodata=1, $
                position=tpos, iso=1, $
                xtitle=xtitle, xstyle=5, xrange=scaled_xrange, $
                ytitle=ytitle, ystyle=5, yrange=scaled_xrange, $
                xticklen=xticklen, yticklen=yticklen, $
                _extra=ex

            dims = size(the_fluxs,dimensions=1)
            ndis = dims[1]
            nang = dims[0]
            for i=0,ndis-1 do begin
                for j=0,nang-1 do begin
                    if the_fluxs[j,i] eq 0 then continue

                    index = where(the_fluxs[j,i] ge c_levels, count)
                    if count eq 0 then continue
                    tc = colors[index[count-1]]

                    tcdis = scaled_diss[j,i,*]
                    tcang = the_angles[j,i,*]
                    tcdis = tcdis[[0,1,1,0,0]]
                    tcang = tcang[[0,0,1,1,0]]

                    tx = tcdis*cos(tcang)
                    ty = tcdis*sin(tcang)

                    ; Can extrude a little.
                    index = where($
                        tx gt scaled_xrange[0] or tx lt scaled_xrange[1] or $
                        ty gt scaled_xrange[0] or ty lt scaled_xrange[1] , count)
                    if count eq 0 then continue
                    polyfill, tx,ty, data=1, color=tc
                endfor
            endfor
        endelse


        ; Draw axis.
        plot, xrange, xrange, noerase=1, nodata=1, $
            position=tpos, iso=1, $
            xtitle=xtitle, xstyle=1, xrange=scaled_xrange, $
            ytitle=ytitle, ystyle=1, yrange=scaled_xrange, $
            xticklen=xticklen, yticklen=yticklen, $
            xticks=xticks, xtickv=scaled_xtickv, xtickname=xtickn, $
            yticks=xticks, ytickv=scaled_xtickv, ytickname=xtickn, $
            xminor=xminor, yminor=yminor, $
            xtickformat=xtickformat, ytickformat=ytickformat, $
            _extra=ex

        tx = (tpos[0]+tpos[2])*0.5
        ty = tpos[3]+ychsz*0.5
        xyouts, tx,ty, title, normal=1, color=black, alignment=0.5, charsize=label_size
        
        ; Add lines at every 45 deg.
        tts = smkarthm(45,360,45,'dx')*constant('rad')
        dis = [0,xrange[1]]*2
        foreach tmp, tts do begin
            oplot, dis*cos(tmp), dis*sin(tmp), color=black, linestyle=2
        endforeach
        
        ; Add circles.
        tmp = findgen(101)*2*!dpi/100
        txs = cos(tmp)
        tys = sin(tmp)
        ncircle = n_elements(scaled_circles)
        for ii=0, ncircle-1 do begin
            plots, txs*scaled_circles[ii], tys*scaled_circles[ii], linestyle=2, color=black
        endfor
        
        ; Add minor ticks.
        minor_tick_ratio = 0.6
        if scale_method eq 'log' or scale_method eq 'default' then begin
            if n_elements(orig_xtickv) ne 0 then begin
                for ii=0,xticks do begin
                    minor_vals = smkgmtrc(orig_xtickv[ii]*0.1,orig_xtickv[ii],10,'n')
                    index = lazy_where(minor_vals, '()', orig_xtickv[ii]*[0.1,1], count=count)
                    if count eq 0 then continue
                    minor_vals = minor_vals[index]
                    scaled_minor_vals = scale_dis(minor_vals,scale_method)
                    if scaled_xtickv[ii] lt 0 then scaled_minor_vals = -scaled_minor_vals
                    foreach tval, scaled_minor_vals do begin
                        ; Add minor ticks on x-axis.
                        dy = abs_ticklen*minor_tick_ratio
                        foreach ty, scaled_xrange, id do begin
                            tx = tval
                            tmp = convert_coord(tx,ty, data=1, to_normal=1)
                            xs = tmp[0]+[0,0]
                            ys = tmp[1]+[0,1]*dy*(1-id*2)
                            plots, xs, ys, normal=1
                        endforeach
                        
                        ; Add minor ticks on y-axis.
                        dx = abs_ticklen*minor_tick_ratio
                        foreach tx, scaled_xrange, id do begin
                          ty = tval
                          tmp = convert_coord(tx,ty, data=1, to_normal=1)
                          xs = tmp[0]+[0,1]*dx*(1-id*2)
                          ys = tmp[1]+[0,0]
                          plots, xs, ys, normal=1
                        endforeach
                    endforeach
                    
                    if orig_xtickv[ii] ne max(orig_xtickv) then continue
                    minor_vals = smkgmtrc(orig_xtickv[ii],orig_xtickv[ii]*10,10,'n')
                    index = lazy_where(minor_vals, '()', [orig_xtickv[ii],xrange[1]], count=count)
                    if count eq 0 then continue
                    minor_vals = minor_vals[index]
                    scaled_minor_vals = scale_dis(minor_vals,scale_method)
                    if scaled_xtickv[ii] lt 0 then scaled_minor_vals = -scaled_minor_vals
                    foreach tval, scaled_minor_vals do begin
                      ; Add minor ticks on x-axis.
                      dy = abs_ticklen*minor_tick_ratio
                      foreach ty, scaled_xrange, id do begin
                        tx = tval
                        tmp = convert_coord(tx,ty, data=1, to_normal=1)
                        xs = tmp[0]+[0,0]
                        ys = tmp[1]+[0,1]*dy*(1-id*2)
                        plots, xs, ys, normal=1
                      endforeach

                      ; Add minor ticks on y-axis.
                      dx = abs_ticklen*minor_tick_ratio
                      foreach tx, scaled_xrange, id do begin
                        ty = tval
                        tmp = convert_coord(tx,ty, data=1, to_normal=1)
                        xs = tmp[0]+[0,1]*dx*(1-id*2)
                        ys = tmp[1]+[0,0]
                        plots, xs, ys, normal=1
                      endforeach
                    endforeach
                endfor
            endif
        endif


        if keyword_set(test) then stop
        if keyword_set(gen_figure) then sgclose
    endforeach

    return, retval



end


time_range = ['2013-06-01/02:00','2013-06-01/08:00']
time_range = ['2013-06-01/05:49','2013-06-01/06:50']
probe = 'a'
the_species = ['o','p']

time_range = ['2013-05-01/07:30','2013-05-01/07:55']
time_range = ['2013-06-28/10:00','2013-06-28/10:30']
probe = 'a'
the_species = ['p']

foreach species, the_species do begin
    var = rbsp_plot_pa2d(time_range, probe=probe, $
      species=species, scale_method='default', unit='energy', zrange=[5e3,5e7], test=1)
endforeach
end