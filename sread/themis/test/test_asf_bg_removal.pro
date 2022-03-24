;+
; Test to remove asf bg, with faster speed
;-

time_range = time_double(['2013-03-17/05:00','2013-03-17/11:00'])   ; garbrielse's example
site = 'gako'


asf_var = 'thg_'+site+'_asf'
if check_if_update(asi_var) then begin
    themis_read_asf, time_range, site=site
endif
get_data, asf_var, times, imgs_raw, limits=lim


;---Calculate the edge and center differently.
    pixel_elev = lim.pixel_elev
    pixel_indices = where(finite(pixel_elev,nan=1), complement=center_indices)

;---Loop through center pixels
    image_size = float(lim.image_size)
    imgs_bg = imgs_raw
    time_step = 3d
    width_for_aurora = 3*60d/time_step
    center_indices = center_indices[0:*:100]
    xxs = times-times[0]
    xtickv = make_bins(minmax(xxs),3600)
    xticks = n_elements(xtickv)-1
    xminor = 6
center_indices = [17222,14934]
    foreach center_index, center_indices do begin
;center_index = 17222
;center_index = 14934
        tmp = array_indices(image_size, dimensions=1, center_index)
        ii = tmp[0]
        jj = tmp[1]
        img_bg = imgs_bg[*,ii,jj]
        img_bg0 = min(img_bg)
        
        ;img_bg1 = smooth(img_bg,600/3d,edge_mirror=1)
        plot, xxs, img_bg, yrange=[1e3,65535], xstyle=1, ystyle=1, ylog=1, xtickv=xtickv, xticks=xticks, xminor=xminor
        foreach val, [1e4,2e4,4e4] do plots, !x.crange, val+[0,0], linestyle=1
        plots, xxs, img_bg0, linestyle=1
;        plots, xxs, calc_baseline(img_bg, 10), color=sgcolor('red')
;        plots, xxs, calc_baseline(img_bg, 250), color=sgcolor('red')
        plots, xxs, calc_baseline(img_bg, 50), color=sgcolor('red')
        stop
        
        
;        img_bg1 = calc_baseline(img_bg, width_for_aurora)
;        plot, xxs, img_bg, yrange=[1e3,65535], xstyle=1, ystyle=1, ylog=1, xtickv=xtickv, xticks=xticks, xminor=xminor
;        foreach val, [1e4,2e4,4e4] do plots, !x.crange, val+[0,0], linestyle=1
;        plots, xxs, img_bg0, linestyle=1
;        plots, xxs, img_bg1, color=sgcolor('red')
;
;        weight = (tanh((img_bg1-3e4)/1e4)+1)*0.5
;        img_bg2 = (img_bg1-img_bg0)*weight+img_bg0
;        vals = (img_bg1-2e4)/4e4
;        plots, xxs, img_bg2, color=sgcolor('purple')
;        stop
    endforeach

for ii=0,255,10 do for jj=0,255,10 do begin
    plot, times, imgs_raw[*,ii,jj], yrange=[0,65536], xstyle=1, ystyle=1
    foreach val, [1e4,2e4,4e4] do plots, !x.crange, val, linestyle=1
    xyouts, 0.5,0.5,normal=1, strjoin(string([ii,jj],format='(I0)'),',')
    wait, 0.2
endfor

end