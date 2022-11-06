;+
; show how to update geopack at each different epoch. 
; use geopack_recalc, no need to return tilt, no need to feed epoch and tilt
; for routines even if they accept the two keywords.
;-

deg = 180d/!dpi
rad = !dpi/180
re = 6378d & re1 = 1d/re
alt = 100   ; km.
r0 = 1+alt*re1

model0 = 't89'
t89 = 1

tplot_options, 'labflag', -1
tplot_options, 'ynozero', 1
tplot_options, 'ystyle', 1
tplot_options, 'symsize', 0.5

utr = time_double(['2013-05-01/07:25','2013-05-01/07:40'])
probe = 'b'
pre0 = 'rbspb_'
posvar = pre0+'pos_gse'
coord0 = 'gse'

; load pos.
efwl3 = sread_rbsp_efw_l3(utr, probes = probe)
if size(efwl3,/type) ne 8 then return
uts = sfmepoch(efwl3.epoch,'unix',/epoch16)
store_data, posvar, uts, efwl3.pos_gse*re1

get_data, posvar, tmp, posgses
uts = smkarthm(min(uts)-(min(uts) mod 60), max(uts), 60, 'dx')
posgses = sinterpol(posgses, tmp, uts)
store_data, posvar, uts, posgses

nrec = n_elements(uts)
ets = stoepoch(uts,'unix')
posgsms = dblarr(nrec,3)


; **** geopack_conv_coord does not use epoch or tilt, but we have to do
; geopack_recalc to get the correct conversion.
tvar0 = pre0+'rz_gsm'
idx = 2
tvar = tvar0+'_noupdate'
tlab = 'no update'
tet = ets[0]
geopack_epoch, tet, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
geopack_recalc, yr, mo, dy, hr, mi, sc+msc*0.001d, /date
for i = 0, nrec-1 do begin
    x0 = posgses[i,0] & y0 = posgses[i,1] & z0 = posgses[i,2]
    geopack_conv_coord, x0, y0, z0, /from_gse, xp, yp, zp, /to_gsm
    posgsms[i,*] = [xp,yp,zp]
endfor
store_data, tvar, uts, posgsms[*,idx], limits = {labels:tlab}


tvar = tvar0+'_gse2gsm'
tlab = 'gse2gsm'
posgsms = sgse2gsm(posgses,ets)
store_data, tvar, uts, posgsms[*,idx], limits = {labels:tlab}


tvar = tvar0+'_recalc'
tlab = 'use recalc'
for i = 0, nrec-1 do begin
    tet = ets[i]
    geopack_epoch, tet, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
    geopack_recalc, yr, mo, dy, hr, mi, sc+msc*0.001d, /date

    x0 = posgses[i,0] & y0 = posgses[i,1] & z0 = posgses[i,2]
    geopack_conv_coord, x0, y0, z0, /from_gse, xp, yp, zp, /to_gsm
    posgsms[i,*] = [xp,yp,zp]
endfor
store_data, tvar, uts, posgsms[*,idx], limits = {labels:tlab}


vars = tnames(tvar0+'_*')
nvar = n_elements(vars)
options, vars, 'psym', -1
options, vars, 'ytitle', 'Z GSM!C(Re)'
options, vars, 'yrange', [1.75,2.25]

tpos = sgcalcpos(nvar, lmargin = 10, bmargin = 5)
ofn = shomedir()+'/geopack_recalc_test_gse2gsm.pdf'
sgopen, ofn, xsize = 5, ysize = 3.5, /inch
tplot, vars, trange = utr, position = tpos
sgclose



; **** trace to ionosphere and get footprint mlat.
dir = -1    ; trace to northern hemisphere.
fptmlats = dblarr(nrec)
fptzgsms = dblarr(nrec)
tvar0 = pre0+'fpt_mlat'
par = 2

; case 1: no update at all.
tvar = tvar0+'_noupdate'
tlab = 'no update'
tet = ets[0]
geopack_epoch, tet, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
geopack_recalc, yr, mo, dy, hr, mi, sc+msc*0.001d, /date
for i = 0, nrec-1 do begin
    xp = posgsms[i,0] & yp = posgsms[i,1] & zp = posgsms[i,2]
    geopack_trace, xp, yp, zp, dir, par, xf, yf, zf, r0 = r0, $
        /refine, /ionosphere, t89 = t89
    
    ; convert from gsm to mag.
    geopack_conv_coord, xf,yf,zf, /from_gsm, txf,tyf,tzf, /to_mag
    fptmlats[i] = asin(tzf/r0)*deg
endfor
store_data, tvar, uts, fptmlats, limits = {labels:tlab}

; case 2: update use geopack_recalc, no tilt.
tvar = tvar0+'_recalc'
tlab = 'use recalc'
for i = 0, nrec-1 do begin
    tet = ets[i]
    geopack_epoch, tet, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
    geopack_recalc, yr, mo, dy, hr, mi, sc+msc*0.001d, /date

    xp = posgsms[i,0] & yp = posgsms[i,1] & zp = posgsms[i,2]
    geopack_trace, xp, yp, zp, dir, par, xf, yf, zf, r0 = r0, $
        epoch = tet, /refine, /ionosphere, t89 = t89
    
    ; convert from gsm to mag.
    geopack_conv_coord, xf,yf,zf, /from_gsm, txf,tyf,tzf, /to_mag
    fptmlats[i] = asin(tzf/r0)*deg
    
    fptzgsms[i] = zf
endfor
store_data, tvar, uts, fptmlats, limits = {labels:tlab}

; case 3: update use epoch, no tilt.
tvar = tvar0+'_epoch'
tlab = 'use epoch'
for i = 0, nrec-1 do begin
    tet = ets[i]

    xp = posgsms[i,0] & yp = posgsms[i,1] & zp = posgsms[i,2]
    geopack_trace, xp, yp, zp, dir, par, xf, yf, zf, r0 = r0, $
        epoch = tet, /refine, /ionosphere, t89 = t89
    
    ; convert from gsm to mag.
    geopack_conv_coord, xf,yf,zf, /from_gsm, txf,tyf,tzf, /to_mag
    fptmlats[i] = asin(tzf/r0)*deg
endfor
store_data, tvar, uts, fptmlats, limits = {labels:tlab}


vars = tnames(tvar0+'_*')
nvar = n_elements(vars)
options, vars, 'ytitle', 'Fpt/MLat!C(deg)'
options, vars, 'psym', -1
options, vars, 'yrange', [63.7,64.35]

tpos = sgcalcpos(nvar, lmargin = 10, bmargin = 5)
ofn = shomedir()+'/geopack_recalc_test_mlat.pdf'
sgopen, ofn, xsize = 5, ysize = 3.5, /inch
tplot, vars, trange = utr, position = tpos
sgclose



; **** why there are sawteeth in footprint?

models = ['t89','t96','t01','t04s']
nmodel = n_elements(models)
for i = 0, nmodel-1 do begin
    model = models[i]
    fptzgsms = dblarr(nrec)
    sgeopack_par, utr, model, /delete
    get_data, model+'_par', tmp, pars
    pars = sinterpol(pars, tmp, uts)
    store_data, model+'_par', uts, pars
    t89 = (model eq 't89')? 1: 0
    t96 = (model eq 't96')? 1: 0
    t01 = (model eq 't01')? 1: 0
    ts04 = (model eq 't01s')? 1: 0
    for j = 0, n_elements(uts)-1 do begin
        tet = ets[j]
        par = pars[j,*]
        geopack_epoch, tet, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
        geopack_recalc, yr, mo, dy, hr, mi, sc+msc*0.001d, /date
        
        xp = posgsms[j,0] & yp = posgsms[j,1] & zp = posgsms[j,2]
        geopack_trace, xp, yp, zp, dir, par, xf, yf, zf, r0 = r0, $
            epoch = tet, /refine, /ionosphere, $
            t89 = t89, t96 = t96, t01 = t01, ts04 = ts04, storm = storm
            
        ; convert from gsm to mag.
        geopack_conv_coord, xf,yf,zf, /from_gsm, txf,tyf,tzf, /to_mag
        fptmlats[j] = asin(tzf/r0)*deg
        
        fptzgsms[j] = zf
    endfor
    store_data, pre0+'fpt_rz_gsm_'+model, uts, fptzgsms, $
        limits = {ytitle:'Fpt Z GSM!C(Re)', labels:strupcase(model)}
endfor


vars = tnames(pre0+'fpt_rz_gsm_*')
nvar = n_elements(vars)
tpos = sgcalcpos(nvar, lmargin = 10, bmargin = 5)

options, vars, 'psym', -1
options, vars, 'yrange', [0.935,0.985]

ofn = shomedir()+'/geopack_sawteeth_in_fpt.pdf'
sgopen, ofn, xsize = 5, ysize = 3.5, /inch
tplot, vars, trange = utr+[-1,1]*1200, position = tpos
sgclose


end
