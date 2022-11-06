;+
; about calc:
;   set one of epoch or tilt is enough, epoch has higher priority when both
;   are set.
; mapping coefficient that maps to the ionosphere at 100 km altitude.
; should be enough to use model field in most cases (at least 25% accuracy).
; do we need to recalc even when ets and tilt are known?

; fpt/mlat/mlon have sawtooth, b/c fpt/gsm pos have sawtooth, but s/c pos/gsm
; is continuous.
; the jump times are not uniform, but looks somewhat regular.
; dir = 1 for northern hemisphere, -1 for southern.
;-

pro scalc_map_coef, posvar, bvar, model = model0, coord = coord0, igrf = igrf, $
    prefix = pre, suffix = suf, dir = dir, altitude = alt

    deg = 180d/!dpi
    rad = !dpi/180
    re = 6378d & re1 = 1d/re
    if ~keyword_set(alt) then alt = 100   ; km.
    r0 = 1+alt*re1
    
    if n_elements(pre) eq 0 then pre = ''
    if n_elements(suf) eq 0 then suf = ''
    if n_elements(model0) eq 0 then model0 = 't89'
    if n_elements(coord0) eq 0 then coord0 = 'gsm'


    t89 = (model0 eq 't89')? 1: 0
    t96 = (model0 eq 't96')? 1: 0
    t01 = (model0 eq 't01')? 1: 0
    t04s = (model0 eq 't04s')? 1: 0
    storm = (model0 eq 't01s')? 1: 0
    model = model0 & if model eq 't01s' then model = 't01'

    get_data, posvar, uts, poss
    nrec = n_elements(uts)
    if nrec eq 0 then message, 'no input data ...'
    ets = stoepoch(uts,'unix')

    utr = minmax(uts)
    sgeopack_par, utr, model, /delete
    if model ne '' then begin
        get_data, model+'_par', tmp, dat
        pars = sinterpol(dat, tmp, uts)
    endif


    ; useful vars.
    mapcoefs = dblarr(nrec)     ; mapping coefficient.
    fptgsms = dblarr(nrec,3)    ; footprint pos in gsm in Re.
    fptmlats = dblarr(nrec)     ; footprint mlat in deg.
    fptmlons = dblarr(nrec)     ; footprint mlon in deg.
    bmods = dblarr(nrec,3)      ; vector model B field in nT.
    posgsms = dblarr(nrec,3)    ; s/c pos in gsm in Re.
    b0mods = dblarr(nrec)
    
    
    
    ; model b.
    for i = 0, nrec-1 do begin
        
        ; prepare.
        tet = ets[i]
        geopack_epoch, tet, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
        geopack_recalc, yr, mo, dy, hr, mi, sc+msc*0.001d, /date
        
        ; model parameters.
        case model of
            't89': par = 2
            't96': par = reform(pars[i,*])
            't01': par = reform(pars[i,*])
            't04s': par = reform(pars[i,*])
        endcase
        
        ; want gsm coord, coord0 is the original coord.
        x0 = poss[i,0] & y0 = poss[i,1] & z0 = poss[i,2]
        case coord0 of
            'gse': $
                geopack_conv_coord, x0, y0, z0, /from_gse, xp, yp, zp, /to_gsm
            'gsm': begin
                xp = x0 & yp = y0 & zp = z0 & end
        endcase
        posgsms[i,*] = [xp,yp,zp]
        
        ; get internal field.
        if keyword_set(igrf) then geopack_igrf_gsm, xp,yp,zp, bxp,byp,bzp $
        else geopack_dip, xp,yp,zp, bxp,byp,bzp
        
        ; get external field.
        case model of
            't89': geopack_t89, par, xp,yp,zp, tbx,tby,tbz
            't96': geopack_t96, par, xp,yp,zp, tbx,tby,tbz
            't01': geopack_t01, par, xp,yp,zp, tbx,tby,tbz
            't01s': geopack_t01, par, xp,yp,zp, tbx,tby,tbz /storm
            't04s': geopack_ts04, par, xp,yp,zp, tbx,tby,tbz
            else: begin tbx = 0 & tby = 0 & tbz = 0 & end
        endcase
        bxp+= tbx & byp+= tby & bzp+= tbz
        bmods[i,*] = [bxp,byp,bzp]
        
    endfor
    b0mods = snorm(bmods)

    
    ; b in vector or in magnitude.
    ; use a smoothed version of measured field or use the model field.
    if n_elements(bvar) ne 0 then begin
        get_data, bvar, tmp, dat
        b0s = sinterpol(dat, tmp, uts)
        if size(b0s,/n_dimension) eq 2 then b0s = snorm(b0s)

        ; remove wave.
        ; should do this in vector, but this is probably ok.
        seclen = 600    ; sec, 10 min.
        minnsec = 5     ; 5 sectors at least.
        nsec = (utr[1]-utr[0])/seclen
        nsec = nsec>minnsec
        b0s = b0mods+scalcbg(b0s-b0mods, nsection = nsec)
    endif else b0s = b0mods
    

    ; trace to ionosphere and get footprint.
    for i = 0, nrec-1 do begin

        ; prepare.
        tet = ets[i]
        geopack_epoch, tet, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
        geopack_recalc, yr, mo, dy, hr, mi, sc+msc*0.001d, /date

        xp = posgsms[i,0] & yp = posgsms[i,1] & zp = posgsms[i,2]
        if n_elements(dir) eq 0 then $
            dir = (zp gt 0)? -1: 1      ; zp gt 0 > northern hemisphere.

        ; model parameters.
        case model of
            't89': par = 2
            't96': par = reform(pars[i,*])
            't01': par = reform(pars[i,*])
            't04s': par = reform(pars[i,*])
        endcase

        geopack_trace, xp, yp, zp, dir, par, xf, yf, zf, r0 = r0, $
            /refine, /ionosphere, $
            t89 = t89, t96 = t96, t01 = t01, ts04 = ts04, storm = storm
        fptgsms[i,*] = [xf,yf,zf]

        ; convert from gsm to mag.
        geopack_conv_coord, xf,yf,zf, /from_gsm, txf,tyf,tzf, /to_mag

        fptmlats[i] = asin(tzf/r0)*deg
        fptmlons[i] = atan(tyf,txf)*deg
        
        ; get the model B field at footprint and s/c pos.
        geopack_igrf_gsm, xf,yf,zf, bxf,byf,bzf

        mapcoefs[i] = snorm([bxf,byf,bzf])/b0s[i]
    endfor
    
    fptmlts = slon2lt(fptmlons, stoepoch(uts,'unix'), /mag, /deg)/15 ; in hour.
    fptmlts = (fptmlts+24) mod 24
    
    store_data, pre+'map_coef'+suf, uts, mapcoefs, $
        limits = {ytitle:'Mapping coef'}
    store_data, pre+'fpt_mlat'+suf, uts, fptmlats, $
        limits = {ytitle:'Fpt/Mlat (deg)'}
    store_data, pre+'fpt_mlon'+suf, uts, fptmlons, $
        limits = {ytitle:'Fpt/Mlon (deg)'}
    store_data, pre+'fpt_mlt'+suf, uts, fptmlts, $
        limits = {ytitle:'Fpt/MLT (hr)'}
    store_data, pre+'bmod_gsm'+suf, uts, bmods, $
        limits = {ytitle:'B model!C(nT)', colors:[6,4,2], $
        labels:'GSM '+['x','y','z']}

end


utr = time_double(['2013-05-01/07:20','2013-05-01/07:50'])
probe = 'b'
pre0 = 'rbspb_'

; load pos.
efwl3 = sread_rbsp_efw_l3(utr, probes = probe)
if size(efwl3,/type) ne 8 then return
uts = sfmepoch(efwl3.epoch,'unix',/epoch16)

store_data, pre0+'pos_gse', uts, efwl3.pos_gse/6378d
    
; load b.
emfisis = sread_rbsp_emfisis(utr, probes = probe)
if size(emfisis,/type) ne 8 then return
uts = sfmepoch(emfisis.epoch,'unix',/tt2000)
store_data, pre0+'b', uts, sqrt(total(emfisis.mag^2,2)), $
    limits = {ytitle:'B magnitude!C(nT)'}

scalc_map_coef, pre0+'pos_gse', pre0+'b', model = 't89', coord = 'gse'

end
