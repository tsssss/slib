pro thm_load_esansst2, trange=trange, probes=probes, no_mask = no_mask, e_mask = e_mask, i_mask = i_mask, manual_i = manual_i, manual_e = manual_e, fill = fill, burst = burst, show_mask = show_mask, combined_i = combined_i, combined_e = combined_e, unit = unit, i_energy = i_energy, e_energy = e_energy, ee_type = ee_type_in, npts_smooth_e = npts_smooth_e, crit_v4j = crit_v4j_in 
;; load esa and sst combined tplot variable using thm_load_sst2. 
;; Inputs:
;;		no_mask: if set, no SST mask will be applied
;;		show_mask: stop and show the masked bins
;;		manual: if set, the routine will ask you to select contaminated bins manually; priority lower than than no_mask, e/i_mask !!![not implemented yet]
;;		fill: if set, the gap between ESA and SST will be filled.
;;		burst: set this to load burst data too
;;		unit: input, to be passed for thm_part_combine, so only works for the 'fill' option
;;		ee_type: the type of esa electron, can be 'r' or 'f' (reduced or full). Default is peer (reduced)
;;		npts_smooth_e: the number of points to smooth electron data (only moments)
;;		crit_v4j: the criterion for the current density to be convincing, the bulk velocity needs to be bigger than a certain value. Default is 30 km/s
;; Outputs:
;;		combined_i/e: outputs, used by other routines. Only work for filled method
;; Input and Output:
;;		e_mask, i_mask: an array to decide SST mask bins. This works for only single spacecraft. If probes are set to be many, i_mask as an input applies to all probes; as an output will give the mask for last probe.
;;		i_energy, e_energy: the energy keyword of thm_part_combine. can be out put or input
;; Created: 06/03/2012, Jiang Liu
;; Updated: 08/16/2022, Jiang Liu

;;;;; default keyword settings
if ~keyword_set(probes) then probes = ['a','b','c','d','e']
if keyword_set(ee_type_in) then begin
	if ~strcmp_or(ee_type_in, ['r', 'f']) then message, 'ee_type set wrong! Must be r or f!' $
	else ee_type = ee_type_in
endif else ee_type = 'r' ;;; default is reduced
if keyword_set(crit_v4j_in) then crit_v4j = crit_v4j_in else crit_v4j = 30 ;; in km/s

eetstr = 'pee'+ee_type
esastr = ['r', ee_type] ;; ion and electron. ion is always reduced

particles = ['i', 'e'] ;; types of particles, useful for loops.

; constants
eVpercc_to_nPa=0.1602/1000.    ; multiply
nTesla2_to_nPa=0.01/25.132741  ; multiply
Pi_scale =1.0                  ; multiply - arbitrary
ident=[1,1,1]

timespan, trange(0), time_double(trange(1))-time_double(trange(0)), /sec

for i = 0, n_elements(probes)-1 do begin
	sc = probes[i]
	
	;;;;;; load support data
	thm_load_state,probe=sc, /get_supp, trange=trange
	thm_load_fit,probe=sc,coord='dsl',suff='_dsl', trange=trange
	thm_cotrans, 'th'+sc+'_fgs_dsl', 'th'+sc+'_fgs_gsm', in_coord='dsl', out_coord='gsm' 
	catch, err
	if err eq 0 then begin
		thm_load_esa_pot,probe=sc, trange=trange
	endif else begin
		dprint, !error_state.msg
	endelse
	catch, /cancel

	;;;;;; Now clean up SST moments
	;;; replace with zeros for Ions at the following: (ions= 0,8,16,24,32,40,47,48,55,56) for no fill, for fill use default
	ibins2mask=make_array(64,/int,value=1)
	if ~keyword_set(i_mask) then begin
		if keyword_set(manual_i) then begin
			thm_part_load,probe=sc,trange=trange,datatype='psif'
			thm_part_products,probe=sc,datatype='psif',trange=trange, sst_sun_bins = -1, output = 'phi'
			tplot, 'th'+sc+'_psif_eflux_phi'
			tm = gettime(/c)
			edit3dbins, thm_part_dist(probe=sc, type='psif',/sst_cal), bins_values,/log
			iallzeros = where(bins_values eq 0)
			isst_mask = iallzeros ;; for fill method
		endif else begin
			iallzeros=[0,8,16,24,32,40,47,48,55,56]
		endelse
		i_mask = iallzeros
	endif else begin
		iallzeros = i_mask
		isst_mask = iallzeros ;; for fill method
	endelse
	;;; and for the electrons at the following: (Electrons = 0,8,24,32,40,47,48,55,56) for no fill, for fill use default
	ebins2mask=make_array(64,/int,value=1)
	if ~keyword_set(e_mask) then begin
		if keyword_set(manual_e) then begin
			thm_part_load,probe=sc,trange=trange,datatype='psef'
			thm_part_products,probe=sc,datatype='psef',trange=trange, sst_sun_bins = -1, output = 'phi'
			tplot, 'th'+sc+'_psef_eflux_phi'
			tm = gettime(/c)
			edit3dbins, thm_part_dist(probe=sc, type='psef',/sst_cal), bins_values,/log
			eallzeros = where(bins_values eq 0)
			esst_mask = eallzeros
		endif else begin
			eallzeros=[0,8,24,32,40,47,48,55,56]
		endelse
		e_mask = eallzeros
	endif else begin
		eallzeros = e_mask
		esst_mask = eallzeros
	endelse
	;;; no_mask will overwrite everything
	if keyword_set(no_mask) then begin
		isst_mask = -1 ;; for fill method
		esst_mask = -1
	endif else begin
		ibins2mask(iallzeros)=0
		ebins2mask(eallzeros)=0
		;;; print the masked bins
		if keyword_set(show_mask) then begin
			print, 'i masks:'
			print, iallzeros
			print, 'e masks:'
			print, eallzeros
			stop
		endif
	endelse

	;;;;;;;;;; load data ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	if keyword_set(fill) then begin
		;;;;;;;; fill, new way ;;;;;;;;;;;
		;;;; ion
		combined_i = thm_part_combine(probe=sc, trange=trange, $
			esa_datatype='peir', sst_datatype='psif', $
			orig_esa=iesa, orig_sst=isst, sst_sun_bins=isst_mask, energies = i_energy, unit = unit) 
		thm_part_products, dist_array=combined_i, outputs=['energy', 'moments'], sc_pot_name = 'th'+sc+'_esa_pot', mag_name = 'th'+sc+'_fgs_dsl'
		;;;; electron
		combined_e = thm_part_combine(probe=sc, trange=trange, $
			esa_datatype=eetstr, sst_datatype='psef', $
			orig_esa=eesa, orig_sst=esst, sst_sun_bins=esst_mask, energies = e_energy, unit = unit) 
		thm_part_products, dist_array=combined_e, outputs=['energy', 'moments'], sc_pot_name = 'th'+sc+'_esa_pot', mag_name = 'th'+sc+'_fgs_dsl'

		;;;;;; copy products to meet required names
		suffs_use = ['avgtemp', 'density', 'ptens', 'velocity', 'magt3', 't3']
		for i_type = 0, n_elements(particles)-1 do begin
			for i_suff = 0, n_elements(suffs_use)-1 do begin
				name_in = 'th'+sc+'_pt'+particles[i_type]+esastr[i_type]+'f_'+suffs_use[i_suff]
				name_out = 'th'+sc+'_pt'+particles[i_type]+'x_'+suffs_use[i_suff]
				copy_data, name_in, name_out
				del_data, name_in

				;;; smooth data if keyword is set
				if keyword_set(npts_smooth_e) and strcmp(particles[i_type], 'e') then begin
					tsmooth2, name_out, npts, newname = name_out ;; [check here]
					print, 'THM_LOAD_ESANSST2: Note: '+name_out+' has been smoothed by'+strcompress(string(fix(npts)))+' points.'
				endif
			endfor
			copy_data, 'th'+sc+'_pt'+particles[i_type]+esastr[i_type]+'f_eflux_energy', 'th'+sc+'_pt'+particles[i_type]+'x_en_eflux'
		endfor

		;;;;; make pressure and temperature variables
		;;; ions: pressure
		calc,"'th"+sc+"_ptix_press'= eVpercc_to_nPa * total('th"+sc+"_ptix_magt3'*('th"+sc+"_ptix_density'#ident),2)/3." ; in nPa
		calc,"'th"+sc+"_ptix_pressmag3'= eVpercc_to_nPa * 'th"+sc+"_ptix_magt3'*('th"+sc+"_ptix_density'#ident)" ; in nPa
		;;; electrons: pressure
		calc,"'th"+sc+"_ptex_press'= eVpercc_to_nPa * total('th"+sc+"_ptex_magt3'*('th"+sc+"_ptex_density'#ident),2)/3." ; in nPa
		calc,"'th"+sc+"_ptex_pressmag3'= eVpercc_to_nPa * 'th"+sc+"_ptex_magt3'*('th"+sc+"_ptex_density'#ident)" ; in nPa
		;;; plasma (i+e) pressure
		tinterpol_mxn,'th'+sc+'_ptex_press','th'+sc+'_ptix_density',newname='th'+sc+'_ptex_press_int'
		calc,"'th"+sc+"_ptxx_press'='th"+sc+"_ptix_press'+'th"+sc+"_ptex_press_int'"
		tinterpol_mxn,'th'+sc+'_ptex_pressmag3','th'+sc+'_ptix_density',newname='th'+sc+'_ptex_pressmag3_int'
		calc,"'th"+sc+"_Pthmag3'='th"+sc+"_ptix_pressmag3'+'th"+sc+"_ptex_pressmag3_int'"
		
		;;; ion: temperature
		calc," 'th"+sc+"_ptix_T' = 'th"+sc+"_ptix_press'/(eVpercc_to_nPa * 'th"+sc+"_ptix_density')" ; in eV 
		;;; electron: temperature
		calc," 'th"+sc+"_ptex_T' = 'th"+sc+"_ptex_press'/(eVpercc_to_nPa * 'th"+sc+"_ptex_density')" ; in eV 
		;;; thermal (i+e) pressure
		calc," 'th"+sc+"_ptxx_T' = 'th"+sc+"_ptxx_press'/(eVpercc_to_nPa * 'th"+sc+"_ptix_density')" ; in eV

	endif else begin

		;;;;;;;; no fill, old way ;;;;;;;;;;;
		thm_load_sst2,probe=sc, trange=trange
		catch, err
		if err eq 0 then begin
			thm_load_esa_pkt,probe=sc, trange=trange
		endif else begin
			dprint, !error_state.msg
		endelse
		catch, /cancel
			
		;; Now clean up ESA moments
		thm_part_moments, probe = sc, instrum = ['peir', eetstr], scpot_suffix = '_esa_pot', $
		trange=trange, mag_suffix = '_fgs_dsl', tplotnames = tn, $
		verbose = 2, /bgnd_remove
		
		; contamination removal
		thm_part_moments, probe = sc, instrum = 'psif', $
		trange=trange,mag_suffix = '_fgs_dsl', tplotnames = tn, $
		sun_bins=ibins2mask, enoise_remove_method='fill', $
		verbose = 2, /sst_cal; new names are output into tn
		;
		; contamination removal
		thm_part_moments, probe = sc, instrum = 'psef', $
		trange=trange,mag_suffix = '_fgs_dsl', tplotnames = tn, $
		sun_bins=ebins2mask, enoise_remove_method='fill', $
		verbose = 2, /sst_cal; new names are output into tn
		
		if keyword_set(burst) then begin
			; ion burst data
			thm_part_moments, probe = sc, instrum = 'psib', $
			trange=trange,mag_suffix = '_fgs_dsl', tplotnames = tn, $
			sun_bins=ebins2mask, enoise_remove_method='fill', $
			verbose = 2, /sst_cal; new names are output into tn
			
			; electron burst data
			thm_part_moments, probe = sc, instrum = 'pseb', $
			trange=trange,mag_suffix = '_fgs_dsl', tplotnames = tn, $
			sun_bins=ebins2mask, enoise_remove_method='fill', $
			verbose = 2, /sst_cal; new names are output into tn
		endif
		
		; get the phi plots
		thm_part_getspec, probe=sc, trange=trange, theta=[-90,90], phi=[-180,180], data_type='psif', start_angle=-180, angle='phi', method_clean='manual',sun_bins=ibins2mask,/sst_cal
		thm_part_getspec, probe=sc, trange=trange, theta=[-90,90], phi=[-180,180], data_type='peir', start_angle=-180, angle='phi'
		
		;;;;;;;;; Combine ESA and SST moments ;;;;;;;;;;;;;;;;;;
		;;;ions: density
		tinterpol_mxn,'th'+sc+'_psif_density','th'+sc+'_peir_density',newname='th'+sc+'_psif_density_int'
		calc," 'th"+sc+"_ptix_density' = 'th"+sc+"_psif_density_int' + 'th"+sc+"_peir_density' "
		;;;electons: density
		tinterpol_mxn,'th'+sc+'_psef_density','th'+sc+'_'+eetstr+'_density',newname='th'+sc+'_psef_density_int'
		calc," 'th"+sc+"_ptex_density' = 'th"+sc+"_psef_density_int' + 'th"+sc+"_"+eetstr+"_density' "
		
		;;;ions: velocity
		tinterpol_mxn,'th'+sc+'_psif_velocity','th'+sc+'_peir_density',newname='th'+sc+'_psif_velocity_int'
		calc,"'th"+sc+"_ptix_velocity'=('th"+sc+"_psif_velocity_int'*('th"+sc+"_psif_density_int'#ident)+'th"+sc+"_peir_velocity'*('th"+sc+"_peir_density'#ident))/('th"+sc+"_ptix_density'#ident)"
		
		;;; electrons: velocity
		tinterpol_mxn,'th'+sc+'_psef_velocity','th'+sc+'_'+eetstr+'_density',newname='th'+sc+'_psef_velocity_int'
		calc,"'th"+sc+"_ptex_velocity'=('th"+sc+"_psef_velocity_int'*('th"+sc+"_psef_density_int'#ident)+'th"+sc+"_"+eetstr+"_velocity'*('th"+sc+"_"+eetstr+"_density'#ident))/('th"+sc+"_ptex_density'#ident)"
		
		;;;ions: flux spectra
		combine_spec, 'th'+sc+'_psif_en_eflux', 'th'+sc+'_peir_en_eflux', newname = 'th'+sc+'_ptix_en_eflux'
		options, 'th'+sc+'_ptix_en_eflux', ytitle = 'Ion Energy', ysubtitle = '[eV]', ztitle = 'eV/(cm^2-sec-sr-eV)', ylog = 1, zlog = 1, spec=1
		ylim,'th'+sc+'_ptix_en_eflux',5,1e6,1
		zlim,'th'+sc+'_ptix_en_eflux',1e2,5e6,1
		;;;electrons: flux spectra
		combine_spec, 'th'+sc+'_psef_en_eflux', 'th'+sc+'_'+eetstr+'_en_eflux', newname = 'th'+sc+'_ptex_en_eflux'
		options, 'th'+sc+'_ptex_en_eflux', ytitle = 'Electron Energy', ysubtitle = '[eV]', ztitle = 'eV/(cm^2-sec-sr-eV)', ylog = 1, zlog = 1, spec=1
		ylim,'th'+sc+'_ptex_en_eflux',5,1e6,1
		zlim,'th'+sc+'_ptex_en_eflux',1e2,5e8,1
		
		;;;esa ions: pressure
		calc,"'th"+sc+"_peir_press'= total('th"+sc+"_peir_magt3'*('th"+sc+"_peir_density'#ident),2)/3." ; in eVpercc
		;;;esa electrons: pressure
		calc,"'th"+sc+"_"+eetstr+"_press'= total('th"+sc+"_"+eetstr+"_magt3'*('th"+sc+"_"+eetstr+"_density'#ident),2)/3." ; in eVpercc
		;;;esa ions and electrons: pressure
		tinterpol_mxn,'th'+sc+'_'+eetstr+'_press','th'+sc+'_peir_density',newname='th'+sc+'_'+eetstr+'_press_int' ; in eVpercc
		calc,"'th"+sc+"_pexr_press'='th"+sc+"_peir_press'+'th"+sc+"_"+eetstr+"_press_int'" ; in eVpercc
		
		;;;sst ions: pressure
		calc,"'th"+sc+"_psif_press'= total('th"+sc+"_psif_magt3'*('th"+sc+"_psif_density'#ident),2)/3." ; in eVpercc
		;;;sst electrons: pressure
		calc,"'th"+sc+"_psef_press'= total('th"+sc+"_psef_magt3'*('th"+sc+"_psef_density'#ident),2)/3." ; in eVpercc
		;;;sst ions and electrons: pressure
		tinterpol_mxn,'th'+sc+'_psef_press','th'+sc+'_psif_density',newname='th'+sc+'_psef_press_int' ; in eVpercc
		calc,"'th"+sc+"_psxf_press'='th"+sc+"_psif_press'+'th"+sc+"_psef_press_int'" ; in eVpercc
		
		;;;esa+sst ion pressure and temperature
		tinterpol_mxn,'th'+sc+'_psif_press','th'+sc+'_peir_density',newname='th'+sc+'_psif_press_int' ; in eVpercc
		calc," 'th"+sc+"_ptix_press' = eVpercc_to_nPa * ('th"+sc+"_psif_press_int' + 'th"+sc+"_peir_press') " ; in nPa
		calc," 'th"+sc+"_ptix_T' = 'th"+sc+"_ptix_press'/(eVpercc_to_nPa * 'th"+sc+"_ptix_density')" ; in eV 
		;;;esa+sst electron pressure and temperature
		tinterpol_mxn,'th'+sc+'_psef_press','th'+sc+'_'+eetstr+'_density',newname='th'+sc+'_psef_press_int'; in eVpercc
		calc," 'th"+sc+"_ptex_press' = eVpercc_to_nPa * ('th"+sc+"_psef_press_int' + 'th"+sc+"_"+eetstr+"_press') " ; in nPa
		calc," 'th"+sc+"_ptex_T' = 'th"+sc+"_ptex_press'/(eVpercc_to_nPa * 'th"+sc+"_ptex_density')" ; in eV 
		;;;esa+sst thermal (i+e) pressure
		tinterpol_mxn,'th'+sc+'_ptex_press','th'+sc+'_peir_density',newname='th'+sc+'_ptex_press_int' ; in nPa
		calc," 'th"+sc+"_ptxx_press' = 'th"+sc+"_ptix_press' + 'th"+sc+"_ptex_press_int'" ; in nPa ;; include all
		calc," 'th"+sc+"_ptxx_T' = 'th"+sc+"_ptxx_press'/(eVpercc_to_nPa * 'th"+sc+"_ptix_density')" ; in eV
	endelse ;; else of fill or not

	;;;; transform velocity
	thm_cotrans,'th'+sc+'_ptix_velocity', 'th'+sc+'_ptix_velocity_gsm', in_coord='dsl', out_coord='gsm' 
	thm_cotrans,'th'+sc+'_ptex_velocity', 'th'+sc+'_ptex_velocity_gsm', in_coord='dsl', out_coord='gsm' 

	;;;; mark density
	;; ion
	options, 'th'+sc+'_ptix_density', ytitle='Ni', ysubtitle='[cm^-3]', ylog=1
	get_data, 'th'+sc+'_ptix_density', data = ni
	catch, err
	if err eq 0 then begin
		ylim, 'th'+sc+'_ptix_density', min(ni.y)*0.33, max(ni.y)*3
		options, 'th'+sc+'_ptix_density', ylog=1
	endif else begin
		dprint, !error_state.msg
	endelse
	catch, /cancel
	;; electron
	options, 'th'+sc+'_ptex_density', ytitle='Ne', ysubtitle='[cm^-3]', ylog=1
	get_data, 'th'+sc+'_ptex_density', data = nelec
	catch, err
	if err eq 0 then begin
		ylim, 'th'+sc+'_ptex_density', min(nelec.y)*0.33, max(nelec.y)*3
		options, 'th'+sc+'_ptex_density', ylog=1
	endif else begin
		dprint, !error_state.msg
	endelse
	catch, /cancel
	
	;;; make thermal pressure Pi and Pe
	get_data, 'th'+sc+'_ptix_press', data=Pi
	get_data, 'th'+sc+'_ptex_press_int', data=Pe
	;; Pth: |Pi|Pe|Pth|
	catch, err
	if err eq 0 then begin
		store_data,'th'+sc+'_Pth',data={x:Pi.x, y:[[Pi.y],[Pe.y],[Pi.y+Pe.y]]}
		options,'th'+sc+'_Pth',colors=[2,4,6], ytitle='Pressure', ysubtitle='[nPa]', labels=['P!di','P!de','P!dth'], ylog=1, labflag = 1
	endif else begin
		dprint, !error_state.msg
	endelse
	catch, /cancel
		
	;;; Combine magnetic and particle pressures
	calc," 'th"+sc+"_fgs_press' = nTesla2_to_nPa * total('th"+sc+"_fgs_gsm'^2,2) "
	tinterpol_mxn,'th'+sc+'_fgs_press','th'+sc+'_ptxx_press',newname='th'+sc+'_fgs_press_int'
	calc," 'th"+sc+"_tot_press' = 'th"+sc+"_fgs_press_int' + 'th"+sc+"_ptxx_press'"
	get_data, 'th'+sc+'_fgs_press_int', data=Pb
	get_data, 'th'+sc+'_ptxx_press', data=Pth
	get_data, 'th'+sc+'_tot_press', data=Pttl
	;; Pall: |Pb|Pth|Ptotal|
	catch, err
	if err eq 0 then begin
		store_data,'th'+sc+'_Pall',data={x:Pttl.x, y:[[Pb.y],[Pth.y],[Pttl.y]]}
		options,'th'+sc+'_Pall',colors=[2,4,0], ytitle='Pressure', ysubtitle='[nPa]', labels=['P!db','P!dth','P!dttl'], ylog=1, labflag = 1
		; plasma beta
		store_data, 'th'+sc+'_beta', data={x:Pth.x, y:Pth.y/Pb.y}
		options,'th'+sc+'_beta', ytitle='Beta', ysubtitle='(ESA+SST)', ylog=1
		; parallel and perpendicular beta
		get_data, 'th'+sc+'_Pthmag3', t_Pthmag3, dataPthmag3
		store_data, 'th'+sc+'_betamag3', data={x:t_Pthmag3, y:dataPthmag3/[[Pb.y],[Pb.y],[Pb.y]]}
		store_data, 'th'+sc+'_betamag2', data={x:t_Pthmag3, y:[[0.5*(dataPthmag3[*,0]+dataPthmag3[*,1])], [dataPthmag3[*,2]]]/[[Pb.y],[Pb.y]]}
		options, 'th'+sc+'_betamag2', colors = [0, 6], labels = ['beta!dperp', 'beta!dpar'], labflag = 1
	endif else begin
		dprint, !error_state.msg
	endelse
	catch, /cancel
		
	;;;; Combine temperatures |Ti|Te|T|
	tinterpol_mxn,'th'+sc+'_ptex_T','th'+sc+'_ptix_T',newname='th'+sc+'_ptex_T_int'
	get_data, 'th'+sc+'_ptix_T', data=Ti
	get_data, 'th'+sc+'_ptex_T_int', data=Te
	get_data, 'th'+sc+'_ptxx_T', data=T
	catch, err
	if err eq 0 then begin
		store_data,'th'+sc+'_Tie',data={x:T.x, y:[[Ti.y],[Te.y]]}
		store_data,'th'+sc+'_Tall',data={x:T.x, y:[[Ti.y],[Te.y],[T.y]]}
		options,'th'+sc+'_Tie',colors=[2,4], ytitle='Temperature', ysubtitle='!c[eV]', labels=['T!di','T!de'], ylog=1, labflag = 1
		options,'th'+sc+'_Tall',colors=[2,4,0], ytitle='Temperature', ysubtitle='!c[eV]', labels=['T!di','T!de','T'], ylog=1, labflag = 1
	endif else begin
		dprint, !error_state.msg
	endelse
	catch, /cancel
	;
	;;;;;;;;;;;;;; Viperp and, parapllel positive, anti-parallel negative VixB ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	tinterpol_mxn,'th'+sc+'_fgs_dsl','th'+sc+'_ptix_velocity',newname='th'+sc+'_fgs_dsl_int'
	tnormalize,'th'+sc+'_fgs_dsl_int',newname='th'+sc+'_fgs_dsl_int_unit'
	del_data, 'th'+sc+'_bvn_dotp'
	tdotp,'th'+sc+'_ptix_velocity','th'+sc+'_fgs_dsl_int_unit',newname='th'+sc+'_bvn_dotp' ;; this is vpar, value only
	get_data,'th'+sc+'_bvn_dotp',data=thx_bvn_dotp
	i_smallvpar = where(abs(thx_bvn_dotp.y) lt crit_v4j, n_smallvpar)
	get_data,'th'+sc+'_fgs_dsl_int_unit',data=thx_fgs_dsl_int_unit
	catch, err
	if err eq 0 then begin
	store_data,'th'+sc+'_ptix_vpar',data={x:thx_bvn_dotp.x, $ ;; this is vpar, three components
	   y:[[thx_fgs_dsl_int_unit.y(*,0)*thx_bvn_dotp.y(*)], $
	      [thx_fgs_dsl_int_unit.y(*,1)*thx_bvn_dotp.y(*)], $
	      [thx_fgs_dsl_int_unit.y(*,2)*thx_bvn_dotp.y(*)]] }
	dif_data,'th'+sc+'_ptix_velocity','th'+sc+'_ptix_vpar', $
		newname='th'+sc+'_ptix_vperp'
	endif else begin
		dprint, !error_state.msg
	endelse
	catch, /cancel
	thm_cotrans,'th'+sc+'_ptix_vpar', 'th'+sc+'_ptix_vpar_gsm', in_coord='dsl', out_coord='gsm' 
	thm_cotrans,'th'+sc+'_ptix_vperp', 'th'+sc+'_ptix_vperp_gsm', in_coord='dsl', out_coord='gsm' 

	;; compute j//i from vpar
	calc, "'th"+sc+"_ptix_jpar' = 1.6e-1*'th"+sc+"_bvn_dotp'*'th"+sc+"_ptix_density'" ;; nA/m2, parapllel positive, anti-parallel negative
	;; mark j from too small vpar to be nan
	if n_smallvpar gt 0 then begin
		get_data, 'th'+sc+'_ptix_jpar', t, jpar
		jpar[i_smallvpar] = !values.f_nan
		store_data, 'th'+sc+'_ptix_jpar', data={x:t, y:jpar}
	endif

	tinterpol_mxn,'th'+sc+'_fgs_gsm','th'+sc+'_ptix_vperp_gsm',newname='th'+sc+'_fgs_gsm_int'
	split_vec, 'th'+sc+'_fgs_gsm_int'
	calc, "'th"+sc+"_ptix_jpar_ew' = 'th"+sc+"_fgs_gsm_int_x'/abs('th"+sc+"_fgs_gsm_int_x')*'th"+sc+"_ptix_jpar'" ;; positive/negative is Earthward/tailward

	;; make tv pretty
	get_data, 'th'+sc+'_ptix_velocity_gsm', t, v_full
	get_data, 'th'+sc+'_ptix_vpar_gsm', t, v_par
	get_data, 'th'+sc+'_ptix_vperp_gsm', t, v_perp
	if err eq 0 then begin
		v_full_span = max(v_full)-min(v_full)
		ylim, 'th'+sc+'_ptix_velocity_gsm', min(v_full)-0.1*v_full_span, max(v_full)+0.1*v_full_span
		v_par_span = max(v_par)-min(v_par)
		ylim, 'th'+sc+'_ptix_vpar_gsm', min(v_par)-0.1*v_par_span, max(v_par)+0.1*v_par_span
		v_perp_span = max(v_perp)-min(v_perp)
		ylim, 'th'+sc+'_ptix_vperp_gsm', min(v_perp)-0.1*v_perp_span, max(v_perp)+0.1*v_perp_span
	endif else begin
		dprint, !error_state.msg
	endelse
	options, 'th'+sc+'_ptix_vpar_gsm', colors=[2,4,6], ytitle='Vi!dpar!nGSM', labels=['V!dx','V!dy','V!dz'], ysubtitle='km/s', labflag = 1
	options, 'th'+sc+'_ptix_vperp_gsm', colors=[2,4,6], ytitle='Vi!dperp!nGSM', labels=['V!dx','V!dy','V!dz'], ysubtitle='km/s', labflag = 1
	options, 'th'+sc+'_ptix_jpar', ytitle='j!di,par!n', ysubtitle='[nA/m!u2!n]'
	options, 'th'+sc+'_ptix_jpar_ew', ytitle='j!di,par, earthw!n', ysubtitle='[nA/m!u2!n]'
	
	;; the electric field inferred by vixB
	tcrossp, 'th'+sc+'_fgs_gsm_int', 'th'+sc+'_ptix_vperp_gsm', newname='th'+sc+'_vixb_gsm'
	calc, "'th"+sc+"_vixb_gsm' = 0.001*'th"+sc+"_vixb_gsm'"
	options, 'th'+sc+'_vixb_gsm', ytitle = 'E=-vixB', ysubtitle = '[mV/m]', labels = ['Ex','Ey','Ez'], colors = [2, 4, 6], labflag = 1
	

	;;;;;;;;;;;;;; Veperp and VexB [Note: this is not a simple repetition of above computation for i. Cannot do a loop to do both.] ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	del_data, 'th'+sc+'_fgs_dsl_int*'
	tinterpol_mxn,'th'+sc+'_fgs_dsl','th'+sc+'_ptex_velocity',newname='th'+sc+'_fgs_dsl_int'
	tnormalize,'th'+sc+'_fgs_dsl_int',newname='th'+sc+'_fgs_dsl_int_unit'
	del_data, 'th'+sc+'_bvn_dotp'
	tdotp,'th'+sc+'_ptex_velocity','th'+sc+'_fgs_dsl_int_unit',newname='th'+sc+'_bvn_dotp' ;; this is vpar, value only
	get_data,'th'+sc+'_bvn_dotp',data=thx_bvn_dotp
	i_smallvpar = where(abs(thx_bvn_dotp.y) lt crit_v4j, n_smallvpar)
	get_data,'th'+sc+'_fgs_dsl_int_unit',data=thx_fgs_dsl_int_unit
	catch, err
	if err eq 0 then begin
	store_data,'th'+sc+'_ptex_vpar',data={x:thx_bvn_dotp.x, $ ;; this is vpar, three components 
	   y:[[thx_fgs_dsl_int_unit.y(*,0)*thx_bvn_dotp.y(*)], $
	      [thx_fgs_dsl_int_unit.y(*,1)*thx_bvn_dotp.y(*)], $
	      [thx_fgs_dsl_int_unit.y(*,2)*thx_bvn_dotp.y(*)]] }
	dif_data,'th'+sc+'_ptex_velocity','th'+sc+'_ptex_vpar', $
		newname='th'+sc+'_ptex_vperp'
	endif else begin
		dprint, !error_state.msg
	endelse
	catch, /cancel
	thm_cotrans,'th'+sc+'_ptex_vpar', 'th'+sc+'_ptex_vpar_gsm', in_coord='dsl', out_coord='gsm' 
	thm_cotrans,'th'+sc+'_ptex_vperp', 'th'+sc+'_ptex_vperp_gsm', in_coord='dsl', out_coord='gsm' 

	;; compute j//e from vpar
	tinterpol_mxn, 'th'+sc+'_ptix_density', 'th'+sc+'_ptex_velocity', newname='th'+sc+'_ptix_density_int'
	calc, "'th"+sc+"_ptex_jpar' = -1.6e-1*'th"+sc+"_bvn_dotp'*'th"+sc+"_ptix_density_int'" ;; nA/m2, parapllel positive, anti-parallel negative. Note ion density is used because more accurate
	;calc, "'th"+sc+"_ptex_jpar' = -1.6e-1*'th"+sc+"_bvn_dotp'*'th"+sc+"_ptex_density'" ;; nA/m2, parapllel positive, anti-parallel negative.
	;; mark j from too small vpar to be nan
	if n_smallvpar gt 0 then begin
		get_data, 'th'+sc+'_ptex_jpar', t, jpar
		jpar[i_smallvpar] = !values.f_nan
		store_data, 'th'+sc+'_ptex_jpar', data={x:t, y:jpar}
	endif

	tinterpol_mxn,'th'+sc+'_fgs_gsm','th'+sc+'_ptex_vperp_gsm',newname='th'+sc+'_fgs_gsm_int'
	split_vec, 'th'+sc+'_fgs_gsm_int'
	calc, "'th"+sc+"_ptex_jpar_ew' = 'th"+sc+"_fgs_gsm_int_x'/abs('th"+sc+"_fgs_gsm_int_x')*'th"+sc+"_ptex_jpar'" ;; positive/negative is Earthward/tailward

	;; make tv pretty
	options, 'th'+sc+'_ptex_vpar_gsm', colors=[2,4,6], ytitle='Ve!dpar!nGSM', labels=['V!dx','V!dy','V!dz'], ysubtitle='km/s', labflag = 1
	options, 'th'+sc+'_ptex_vperp_gsm', colors=[2,4,6], ytitle='Ve!dperp!nGSM', labels=['V!dx','V!dy','V!dz'], ysubtitle='km/s', labflag = 1
	options, 'th'+sc+'_ptex_jpar', ytitle='j!de,par!n', ysubtitle='[nA/m!u2!n]'
	options, 'th'+sc+'_ptex_jpar_ew', ytitle='j!de,par, earthw!n', ysubtitle='[nA/m!u2!n]'
	
	;; the electric field inferred by vixB
	tcrossp, 'th'+sc+'_fgs_gsm_int', 'th'+sc+'_ptex_vperp_gsm', newname='th'+sc+'_vexb_gsm'
	calc, "'th"+sc+"_vexb_gsm' = 0.001*'th"+sc+"_vexb_gsm'"
	options, 'th'+sc+'_vexb_gsm', ytitle = 'E=-vexB', ysubtitle = '[mV/m]', labels = ['Ex','Ey','Ez'], colors = [2, 4, 6], labflag = 1
endfor ;; for of i, probes
end


time_range = time_double(['2017-03-09/06:30','2017-03-09/09:00'])
probe = 'e'
thm_load_esansst2, trange=time_range, probes=probe
end