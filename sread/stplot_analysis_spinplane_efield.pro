;+
; Input is a tplot variable containing one component of spin plane electric field.
; The input data should be in uniform times.
;
; The program calculates the waveforms at 1, 1/3, and 1/10 spin period. The first band
; is the main sine wave; the second band is used to test deviations from sine wave; the
; third band is used to test activity level.
;
; The program uses the 3 bands to determine flags for wake effect. For weak wake,
; comparisons between band 1 and 1/3 can show deviation from sine waves. For strong wake,
; band 1/3 and 1/10 should contain repetative signals at spin period.
;-

pro stplot_analysis_spinplane_efield, evar, spinrate=spinrate, bandscales = bscls

;---Check inputs.
    if n_elements(spinrate) eq 0 then message, 'no spin period ...'
    if tnames(evar) eq '' then message, 'no data ...'
    get_data, evar, uts, dat
    nrec = n_elements(uts)
    dr0 = sdatarate(uts)
    if nrec eq 0 then message, 'no data ...'
    if n_elements(bscls) eq 0 then begin
        bscls = [10d,3,1]
    endif
    nbscl = n_elements(bscls)
    sclstrs = string(bscls,format='(I0)')

;---Settings.
    order = 3       ; order for MAT.
    flag_nspin = 4  ; calc flag within n #of spins.
    wake_nspin = 15 ; the domain length, 15 for 15*4=60 spin.
    colors = [6,4,2]

;---Prepare the 3 bands and their amplitudes.
; evar0, evar0_mat, evar0_amp.

    flaguts = uts[0:*:spinrate*flag_nspin/dr0]
    flagnrec = n_elements(flaguts)
    spinrec = spinrate/dr0

    sdespike, dat
    for j=0, order-1 do dat -= smooth(dat, spinrec, /edge_truncate, /nan)
    evar0 = evar+'0'
    store_data, evar0, uts, dat
    stplot_mat, evar0, scale=spinrate/float(bscls)    ; the 3 bands are in pre_dex_mat
    tvar = evar0+'_mat'
    options, tvar, 'ytitle', '(mV/m)'
    options, tvar, 'labels', sclstrs
    options, tvar, 'colors', colors
    options, tvar, 'spec', 0
    options, tvar, 'ylog', 0
    ylim, tvar, -1
    
    get_data, evar0+'_mat', uts, de1s
    de1amps = dblarr(nrec,nbscl)
    for i=0, nbscl-1 do begin
        de1amps[*,i] = sqrt(de1s[*,i]^2+shift(de1s[*,i],bscls[i]/dr0*0.25)^2)
        de1amps[*,i] = smooth(de1amps[*,i],spinrec*bscls[i]*0.5, /edge_truncate, /nan)
    endfor
    store_data, evar0+'_amp', uts, de1amps, limits={colors:colors,labels:sclstrs}

;---Flag for strong wake.
; evar0+flag_spin[3,10].
    get_data, evar0+'_mat', uts, de1s    
    deidx = [0,1]
    wake_cor = [0.6,0.6] ; max tolerable c_correlation.
    for j=0, n_elements(deidx)-1 do begin
        tamps = de1s[*,deidx[j]]
        flag_spin = dblarr(flagnrec)
        for i=0, flagnrec-2 do begin
            tidx = where(uts ge flaguts[i] and uts le flaguts[i+1])
            tdat = tamps[tidx]
            flag_spin[i] = c_correlate(tdat,tdat,spinrec)
        endfor
        flag_spin = smooth(flag_spin, wake_nspin, /nan, /edge_truncate)
        flag_spin = flag_spin ge wake_cor[j]
        store_data, evar0+'_flag_spin'+sclstrs[deidx[j]], flaguts, flag_spin, limits={yrange:[-0.5,1.5]}
    endfor

;---Flag for weak wake: distorted sine wave.
; pre0_dex_flag_wake
    wake_rat0 = 8d
    wake_de0 = 10d
    ; calc the smoothed amplitude for each band.
    get_data, evar0+'_amp', uts, de1amps
    tamps = dblarr(flagnrec,nbscl)
    for i=0, flagnrec-2 do for j=0, nbscl-1 do begin
        tidx = where(uts ge flaguts[i] and uts le flaguts[i+1])
        tamps[i,j] = median(de1amps[tidx,j])
    endfor
    amp1  = tamps[*,2]
    amp3  = tamps[*,1]
    amp10 = tamps[*,0]
    flag_wake = (amp1/amp3*(amp10+1) le wake_rat0) and (amp1*amp10/amp3^2 le 1)
    idx = where(flag_wake ge wake_de0, cnt) & if cnt ne 0 then flag_wake[idx] = 0
    store_data, evar0+'_flag_wake', flaguts, flag_wake, limits={yrange:[-0.5,1.5]}
    
;---Combine flags.
; pre0_dex_flag.
    vars = evar0+'_'+['flag_spin'+sclstrs[deidx],'flag_wake']
    nvar = n_elements(vars)
    flags = fltarr(flagnrec, nvar+1)
    for i=1, nvar do begin
        get_data, vars[i-1], flaguts, tflag
        flags[*,i] = tflag-0.1*i>0
    endfor
    flags[*,0] = total(flags[*,1:nvar],2) ne 0
    store_data, evar0+'_flag', flaguts, flags, limits={yrange:[-0.2,1.2],colors:findgen(nvar+1),labels:['total','spin'+sclstrs[deidx],'wake']}
    
    
    ;tplot, [evar0,evar0+'_'+['amp','mat','flag']]
    ;stop
    store_data, evar0+'_flag_*', /delete
     

end
