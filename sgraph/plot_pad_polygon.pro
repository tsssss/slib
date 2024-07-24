;+
; Plot 2d pitch angle distribution.
;
; pad_fluxs. [ntime,npa,nen]
; pitch_angle_bins. [npa] or [npa+1]
;
; Evolved from sgdistr2d, plot_pa_contour2d_polygon, and rbsp_plot_pa2d.
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


function plot_pad_polygon, pad_var, plot_times=plot_times, $
    position=tpos, is_velocity=is_velocity, axis_title=axis_title, $
    circles=circles, no_axis=no_axis, $
    xrange=xrange, xticks=xticks, xtickv=xtickv, xminor=xminor, $
    color_table=color_table, cbpos=cbpos, no_colorbar=no_colorbar, ncolor=ncolor, color_range=color_range, $
    title=title, ztitle=ztitle, $
    zrange=zrange, zticks=zticks, ztickv=ztickv, zminor=zminor, zticklen=zticklen, $
    test=test, scale_method=scale_method, file_extension=file_extension, _extra=ex


    errmsg = ''
    retval = list()


;---Figure out the dimensions.
    if n_elements(pad_var) eq 0 then begin
        errmsg = 'No pad_var ...'
        return, retval
    endif
    pad_fluxs = get_var_data(pad_var, times=times, settings=settings)
    pad_dims = size(pad_fluxs, dimensions=1)
    npad_dim = n_elements(pad_dims)
    if npad_dim lt 2 then begin
        errmsg = 'Invalid PAD ...'
        return, retval
    endif else if npad_dim eq 2 then begin
        ntime = 1
    endif else if npad_dim eq 3 then begin
        ntime = pad_dims[0]
        pad_dims = pad_dims[1:2]
    endif else begin
        errmsg = 'Invalid PAD ...'
        return, retval
    endelse
    npa_bin = pad_dims[0]
    nen_bin = pad_dims[1]

    ; pa_bins.
    pa_centers = settings.pa_centers
;    pa_boundarys = settings.pa_boundarys
    pa_dims = size(pa_centers, dimensions=1)
    npa_dim = n_elements(pa_dims)
    uniform_pa_bin = npa_dim eq 1

    ; en_bins.
    en_centers = settings.en_centers
;    en_boundarys = settings.en_boundarys
    en_dims = size(en_centers, dimensions=1)
    nen_dim = n_elements(en_dims)
    uniform_en_bin = nen_dim eq 1

    ; en_centers = alog10(energy_bins)
    ; en_boundarys = (en_centers[1:nen_bin-1]+en_centers[0:nen_bin-2])*0.5
    ; en_boundarys = [en_centers[0]*2-en_centers[1],en_boundarys,en_centers[nen_bin-1]*2-en_centers[nen_bin-2]]

    ; en_boundarys = alog10(energy_bins)
    ; en_centers = (en_boundarys[0:nen_bin-1]+en_boundarys[1:nen_bin])*0.5

    ; en_boundarys = 10d^en_boundarys
    ; en_centers = 10d^en_centers


    ; z-settings.
    zlog = 1
    if n_elements(ztitle) eq 0 then begin
        ztitle = 'Log!I10!N ('+settings.unit+')'
    endif
    if n_elements(zrange) eq 0 then begin
        log_zrange = alog10(minmax(pad_fluxs))
        log_zrange >= -1
        log_zrange = [ceil(log_zrange[0]),floor(log_zrange[1])]
        zrange = 10d^log_zrange
    endif
    log_zrange = alog10(zrange)
    log_ztickv = make_bins(log_zrange,1,inner=1)
    if n_elements(ztickv) eq 0 then ztickv = 10^log_ztickv
    if n_elements(zticks) eq 0 then zticks = n_elements(ztickv)-1
    if n_elements(zminor) eq 0 then zminor = 9

    ; color settings.
    if n_elements(ncolor) eq 0 then ncolor = 15
    if n_elements(color_range) ne 2 then color_range = [10,250]
    color_top = color_range[1]
    color_bottom = color_range[0]
    if n_elements(color_table) eq 0 then color_table = 40
    index_colors = floor(smkarthm(color_bottom,color_top,ncolor,'n'))
    colors = index_colors
    for ii=0,ncolor-1 do colors[ii] = sgcolor(index_colors[ii],ct=color_table)
    log_c_levels = smkarthm(log_zrange[0],log_zrange[1],ncolor,'n')
    c_levels = 10.^log_c_levels

    ; unit related settings.
    if n_elements(unit) eq 0 then unit = 'energy'
    supported_units = ['energy','velocity']
    index = where(supported_units eq unit, count)
    if count eq 0 then begin
        errmsg = 'Invalid unit: '+unit+' ...'
        return, retval
    endif
    if n_elements(axis_title) eq 0 then axis_title = (unit eq 'velocity')? 'V (km/s)': 'E (eV)'


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


;---Generate plot.
    if n_elements(plot_times) eq 0 then plot_times = times
    mission = settings.mission
    probe = settings.probe
    species_str = settings.species
    if n_elements(plot_dir) eq 0 then begin
        plot_dir = join_path([homedir(),'pad_polygon',$
            time_string(plot_times[0],tformat='YYYY_MMDD'),mission+probe,species_str])
    endif
    if file_test(plot_dir) eq 0 then file_mkdir, plot_dir
    

    ; plot_times.
    dtime = 0   ; TODO.
    foreach time, plot_times, time_id do begin
        print, mission+', '+probe+', '+species_str+', '+time_string(time)

        the_tid = (where(times eq time, count))[0]
        if count eq 0 then tmp = min(times-time, the_tid, abs=1)
        fluxs = reform(pad_fluxs[the_tid,*,*])

        ; Energy bins.
        if uniform_en_bin then begin
            energys = en_centers
        endif else begin
            energys = en_centers[the_tid,*]
        endelse

        ; Pitch angle bins.
        if uniform_pa_bin then begin
            angles = pa_centers
        endif else begin
            angles = pa_centers[the_tid,*]
        endelse
        tmp = (angles[1:-1]+angles[0:-2])*0.5
        angle_boundarys = [tmp[0]*2-tmp[1],tmp,tmp[-1]*2-tmp[-2]]
        nangle = n_elements(angles)

        ; Remove duplicated energy bins.
        index = uniq(energys,sort(energys))
        energys = energys[index]
        nenergy = n_elements(energys)
        fluxs = fluxs[*,index]
        
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

        the_angles = fltarr(nangle,nenergy,2)
        the_angles[*,*,0] = (angle_boundarys[0:-2]) # (bytarr(nenergy)+1)
        the_angles[*,*,1] = (angle_boundarys[1:-1]) # (bytarr(nenergy)+1)
        the_angles = the_angles*rad
        
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
        
;        the_diss = [the_diss,reverse(the_diss[1:-2,*,*],1)]        
;        the_angles = [the_angles,reverse(the_angles[1:-2,*,*],1)]
;        the_fluxs = [fluxs,reverse(fluxs[1:-2,*],1)]     ; in [2*npa,nen].
        the_fluxs = fluxs

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
        prefix = mission+probe+'_'
        if n_elements(file_extension) eq 0 then file_extension = 'pdf'
        if gen_figure then begin
            base = prefix+'pad_'+species_str+'_'+time_string(time,tformat='YYYY_MMDD_hhmm_ss')+file_suffix+'_v01.'+file_extension
            plot_file = join_path([plot_dir,base])
            if keyword_set(test) then plot_file = 0
            magn = 1
            if keyword_set(test) then magn = 2 else if file_extension eq 'png' then magn = 2
            sgopen, plot_file, size=fig_size, inch=1, magn=magn
            retval.add, plot_file
            if ~keyword_set(test) then print, plot_file
        endif

        ; Title.
        if n_elements(input_title) eq 0 then begin
            title = strupcase(mission+'-'+probe)+' '+$
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

    ;---Setup the coord.
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
;                index = where($
;                    tx gt scaled_xrange[0] or tx lt scaled_xrange[1] or $
;                    ty gt scaled_xrange[0] or ty lt scaled_xrange[1] , count)
;                if count lt 5 then continue
                if min(tcdis) ge max(scaled_xrange) then continue
                polyfill, tx,ty, data=1, color=tc
                ; symmetric.
                polyfill, tx,-ty, data=1, color=tc
            endfor
        endfor

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
        linestyle=1
        tts = smkarthm(45,360,45,'dx')*constant('rad')
        dis = [0,xrange[1]]*2
        foreach tmp, tts do begin
            oplot, dis*cos(tmp), dis*sin(tmp), color=black, linestyle=linestyle
        endforeach
        
        ; Add circles.
        tmp = findgen(101)*2*!dpi/100
        txs = cos(tmp)
        tys = sin(tmp)
        ncircle = n_elements(scaled_circles)
        for ii=0, ncircle-1 do begin
            plots, txs*scaled_circles[ii], tys*scaled_circles[ii], linestyle=linestyle, color=black
        endfor
        
        ; Add minor ticks.
        minor_tick_ratio = 0.6
        if scale_method eq 'log' or scale_method eq 'default' then begin
            if n_elements(orig_xtickv) ne 0 then begin
                for ii=0,xticks do begin
                    minor_vals = smkgmtrc(orig_xtickv[ii]*0.1,orig_xtickv[ii],10,'n')
                    index = where_pro(minor_vals, '()', orig_xtickv[ii]*[0.1,1], count=count)
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
                    index = where_pro(minor_vals, '()', [orig_xtickv[ii],xrange[1]], count=count)
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

    if n_elements(retval) gt 0 then retval = retval.toarray()
    return, retval

end