;+
; use ideal s/c trajectory and simplest models to show there are
; discontinuities in traced footprint. the discontinuity is probably caused
; by grid in the model.
; 
; and show that peak value at discontinuity should be used, because of
; the comparison between ideal dipole result and the model dipole.
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
tplot_options, 'symsize', 0.2

pre0 = ''
posvar = pre0+'pos_gsm'
coord0 = 'gsm'

; **** load pos.
; 2 hour of data.
dr = 60
nrec = 2*3600/dr

uts = time_double('2013-01-01/00:00')+smkarthm(0,dr,nrec,'x0')
ets = stoepoch(uts,'unix')
utr = minmax(uts)

xgsms = smkarthm(-4.8,-4.5,nrec,'n')
ygsms = dblarr(nrec)
zgsms = smkarthm(1,2,nrec,'n')
;zgsms = dblarr(nrec)
posgsms = [[xgsms],[ygsms],[zgsms]]

store_data, posvar, uts, posgsms, limits = $
    {ytitle:'R GSM!C(Re)', labels:['X','Y','Z']+' GSM', colors:[6,4,2]}



; **** ideal dipole position.
ilats = dblarr(nrec)
for j = 0, nrec-1 do begin
    tet = ets[j]
    geopack_epoch, tet, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
    geopack_recalc, yr, mo, dy, hr, mi, sc+msc*0.001d, /date
    
    xp = posgsms[j,0] & yp = posgsms[j,1] & zp = posgsms[j,2]
    geopack_conv_coord, xp,yp,zp, /from_gsm, txp,typ,tzp, /to_mag, epoch = tet
    lshell = (txp^2+typ^2+tzp^2)^1.5/(txp^2+typ^2)
    ilats[j] = acos(1d/sqrt(lshell))*deg
endfor
store_data, pre0+'ilat', uts, ilats, $
    limits = {ytitle:'ILat!C(deg)'}


; **** sawteeth in original geopack.
models = ['dip','igrf','t89']
nmodel = n_elements(models)
dir = -1
for i = 0, nmodel-1 do begin
    model = models[i]
    fptzgsms = dblarr(nrec)
    fptmlats = dblarr(nrec)
    sgeopack_par, utr, model, /delete
    get_data, model+'_par', tmp, pars
    pars = sinterpol(pars, tmp, uts)
    store_data, model+'_par', uts, pars
    t89 = (model eq 't89')? 1: 0
    t96 = (model eq 't96')? 1: 0
    t01 = (model eq 't01')? 1: 0
    ts04 = (model eq 't04s')? 1: 0
    storm = (model eq 't01s')? 1: 0
    igrf = (model eq 'igrf')? 1: 0
    for j = 0, n_elements(uts)-1 do begin
        tet = ets[j]
        par = pars[j,*]
        geopack_epoch, tet, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
        geopack_recalc, yr, mo, dy, hr, mi, sc+msc*0.001d, /date

        xp = posgsms[j,0] & yp = posgsms[j,1] & zp = posgsms[j,2]
        geopack_trace, xp, yp, zp, dir, par, xf, yf, zf, r0 = r0, $
            epoch = tet, /refine, /ionosphere, $
            igrf = igrf, t89 = t89, t96 = t96, t01 = t01, ts04 = ts04, storm = storm
            
        ; convert from gsm to mag.
        geopack_conv_coord, xf,yf,zf, /from_gsm, txf,tyf,tzf, /to_mag, epoch = tet
        fptmlats[j] = asin(tzf/r0)*deg
        
        fptzgsms[j] = zf
    endfor
    store_data, pre0+'fpt_rz_gsm_'+model, uts, fptzgsms, $
        limits = {ytitle:'Fpt Z GSM!C(Re)', labels:strupcase(model)}
    store_data, pre0+'fpt_mlat_'+model, uts, fptmlats, $
        limits = {ytitle:'Fpt MLat!C(deg)', labels:strupcase(model)}
endfor



device, decomposed = 0
loadct2, 43

vars = tnames(pre0+'fpt_rz_gsm_*')
nvar = n_elements(vars)
tpos = sgcalcpos(nvar)

options, vars, 'psym', -1

ofn = shomedir()+'/geopack_sawteeth_in_fpt_zgsm.pdf'
ofn = 0
sgopen, ofn, xsize = 5, ysize = 3.5, /inch
tplot, vars, trange = utr
sgclose


vars = tnames(pre0+'fpt_mlat_*')
nvar = n_elements(vars)
tpos = sgcalcpos(nvar, lmargin = 10, bmargin = 5)
titl = 'Geopack run, data rate: '+sgnum2str(dr)+ ' sec'


get_data, pre0+'ilat', uts, tmp
get_data, pre0+'fpt_mlat_dip', uts, dat
store_data, pre0+'fpt_mlat_dip', uts, [[tmp],[dat]], $
    limits = {ytitle:'Fpt MLat!C(deg)', labels:['IDEAL','DIP'], colors:[6,0]}

options, vars, 'psym', -1
options, vars, 'yrange', [67.1,77.9]

ofn = shomedir()+'/geopack_sawteeth_in_fpt_mlat_'+sgnum2str(dr)+'sec.pdf'
;ofn = 1
sgopen, ofn, xsize = 5, ysize = 3.5, /inch
device, decomposed = 0
loadct2, 43
tplot, vars, trange = utr, position = tpos;, title = titl
sgclose


end
