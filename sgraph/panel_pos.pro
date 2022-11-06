;+
; Return normalized panel positions.
;
; plot_file. Default is 0.
; fit_method. Default is ''.
;   'fit'. To fit the panels in by scaling and centering.
;   'resize'. To resize to given fig_size.
;
; fig_size=. Output the final xysize.
;
; xsize=. The xsize of the wanted figure.
; ysize=. The ysize of the wanted figure.
;
; pansize=. [xsize,ysize]. In inch.
; panid=. [xid,yid]. [0,0] by default.
;
; nxpan=. # of columns. 1 by default.
; xpads=. Similar to xpad, but in [nxpan-1].
; xpans=. The size ratio in x, in [nxpan].
; nypan=. # of rows. 1 by default.
; ypads=. Similar to ypad, but in [nypan-1].
; ypans=. The size ratio in y, in [nypan].
;
; margins=. [4], [l,b,r,t], lr in xcharsize, bt in ycharsize.
;-

function panel_pos, plot_file, fit_method, fig_size=fig_size, _extra=ex

    if n_elements(plot_file) eq 0 then plot_file = 0
    if n_elements(fit_method) eq 0 then fit_method = ''

    panels = panel_init(plot_file, _extra=ex)
    if fit_method eq 'fit' then begin
        panel_fit, panels, _extra=ex
    endif else if fit_method eq 'resize' then begin
        panel_resize, panels, _extra=ex
    endif

    fig_size = [panels.xsize,panels.ysize]
    return, panel_normalize(panels)

end


poss = panel_pos(nxpan=1, nypan=3, fig_size=fig_size)
end
