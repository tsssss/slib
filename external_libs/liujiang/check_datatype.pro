function check_datatype, datatype, dim = dim, single = single, efi = efi, spec = spec, etype = etype, dsl = dsl, resolution = resolution, file_prefix = file_prefix
;;; chech the tvname, dimension of a certain parameter, for prestore quantities.
; define the dim of the data name to be used
; input: datatype
; output: efi, check whether doing efi
; output: spec, check whether is a spectrum
; output: tv_name, dimension
; output: single: whether this is a single quantity, e. g. ae
; output: dsl: check whether this quantity is in dsl
; output: resolution: the resolution of the data type in seconds
; output: file_prefix: the prefix for the data file


;;;;; tplot name ;;;;;;
;; tplot names
case datatype of
	;;;;;;;;;;;;;;;;;;; THEMIS and RBSP quantities ;;;;;;;;;;;;;;;;;;;;
	;;;; normal quantities
	'pos': tv_name = 'thx_state_pos'
	'pos_rbsp': tv_name = 'thx_state_pos'
	'fgs': tv_name = 'thx_fgs_gsm'
	'fgs_rbsp': tv_name = 'thx_fgs_gsm'
	'fgl': tv_name = 'thx_fgl_gsm'
	'fgl_rbsp': tv_name = 'thx_fgl_gsm'
	'fgh': tv_name = 'thx_fgh_gsm'
	'Blobe': tv_name = 'thx_Blobe'
	'beta': tv_name = 'thx_beta'
	'ni': tv_name = 'thx_ptix_density' ;; not only ESA, both
	'ne': tv_name = 'thx_ptex_density'
	'vi': tv_name = 'thx_ptix_velocity_gsm'
	've': tv_name = 'thx_ptex_velocity_gsm'
	'viperp': tv_name = 'thx_ptix_vperp_gsm' ;; not only ESA, both
	'veperp': tv_name = 'thx_ptex_vperp_gsm'
	'vipar': tv_name = 'thx_ptix_vpar_gsm' ;; not only ESA, both
	'vepar': tv_name = 'thx_ptex_vpar_gsm' ;; not only ESA, both
	'vixy_infer': tv_name = 'thx_ptix_vixy_infer_gsm' ;; not only ESA, both
	'Pth': tv_name = 'thx_Pth'
	'Pall': tv_name = 'thx_Pall'
	'Pb_fgs': tv_name = 'thx_Pb_fgs_gsm'
	'Pttl_fgs': tv_name = 'thx_Pttl_fgs_gsm'
	'Tall': tv_name = 'thx_Tall'
	'ns': tv_name = 'thx_ns_z' ; neutral sheet
	'roi': tv_name = 'thx_state_roi'
	'mode': tv_name = 'thx_hsk_issr_mode_raw' ; fast or slow survey, 0 slow, 1 fast
	'vxb': tv_name = 'thx_vixb_gsm'
	'vixb': tv_name = 'thx_vixb_gsm'
	'vixb_dsl': tv_name = 'thx_vixb_dsl'
	'vexb': tv_name = 'thx_vexb_gsm'
	'vexb_dsl': tv_name = 'thx_vexb_dsl'
	;;;; rbsp moments
	'np_hope_rbsp': tv_name = 'thx_hope_sa_pspec_density'
	'Tp_hope_rbsp': tv_name = 'thx_hope_sa_pspec_avgtemp'
	'Pp_hope_rbsp': tv_name = 'thx_hope_sa_pspec_Pth'
	'ni_hope_rbsp': tv_name = 'thx_hope_sa_ion_density'
	'Ti_hope_rbsp': tv_name = 'thx_hope_sa_ion_avgtemp'
	'Pi_hope_rbsp': tv_name = 'thx_hope_sa_ion_Pth'
	'ne_hope_rbsp': tv_name = 'thx_hope_sa_espec_density'
	'Te_hope_rbsp': tv_name = 'thx_hope_sa_espec_avgtemp'
	'Pe_hope_rbsp': tv_name = 'thx_hope_sa_espec_Pth'
	'Pth_hope_rbsp': tv_name = 'thx_hope_sa_Pth'
	'Pall_hope_rbsp': tv_name = 'thx_hope_sa_Pall'
	'ni_rbsp': tv_name = 'thx_ion_density'
	'Ti_rbsp': tv_name = 'thx_ion_avgtemp'
	'np_rbsp': tv_name = 'thx_pspec_density'
	'Tp_rbsp': tv_name = 'thx_pspec_avgtemp'
	'ne_rbsp': tv_name = 'thx_espec_density'
	'Te_rbsp': tv_name = 'thx_espec_avgtemp'
	'Pth_rbsp': tv_name = 'thx_all_Pth'
	'Pall_rbsp': tv_name = 'thx_all_Pall'
	;;;; rbsp spectra
	'mageis_p': tv_name = 'thx_mageis_pspec'
	'mageis_e': tv_name = 'thx_mageis_espec'
	'rept_p': tv_name = 'thx_rept_pspec'
	'rept_e': tv_name = 'thx_rept_espec'
	'hope_sa_p': tv_name = 'thx_hope_sa_sa_pspec'
	'hope_sa_e': tv_name = 'thx_hope_sa_sa_espec'
	;;;; efi/efw quantities
	'efw_density': tv_name = 'thx_efw_density'
	'efs_rbsp': tv_name = 'thx_efw_esvy_mgse_vxb_removed_coro_removed_spinfit'
	'vsvy_rbsp': tv_name = 'thx_efw_vsvy'
	'efs_dsl': tv_name = 'thx_efs_dsl'
	'efs_dot0_dsl': tv_name = 'thx_efs_dot0_dsl'
	'efs_gsm': tv_name = 'thx_efs_gsm'
	'eff_dsl': tv_name = 'thx_eff_dsl'
	'eff_dot0_dsl': tv_name = 'thx_eff_dot0_dsl'
	'intEy': tv_name = 'thx_intEy'
	'intEy_dsl': tv_name = 'thx_intEy_dsl'
	'vperp_efs': tv_name = 'thx_efs_vperp_gsm'
	'vxy_efs': tv_name = 'thx_efs_vxy_gsm'
	'vperp_eff': tv_name = 'thx_eff_dot0_vperp_gsm'
	'vxy_eff': tv_name = 'thx_eff_dot0_vxy_gsm'
	'vperp_efs_rbsp': tv_name = 'thx_efw_vperp_gsm' ;; for RBSP
	'vperp_efw_rbsp': tv_name = 'thx_efw_vperp_gsm' ;; for RBSP

	;;;;;;;;;;;; MMS quantities ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	'fgs_mms': tv_name = 'mmsx_fgs_gsm'
	'fgl_mms': tv_name = 'mmsx_fgl_gsm'
	'pos_mms': tv_name = 'mmsx_mec_r_gsm' ;; this is in km

	;;;;;;;;;;;; DMSP quantities ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	'dmag_sc_dmsp': tv_name = 'dmspxx_dmag_sc'
	'dmag_nec_dmsp': tv_name = 'dmspxx_dmag_nec'
	'dmagigrf_nec_dmsp': tv_name = 'dmspxx_dmagigrf_nec'
	'vih_dmsp': tv_name = 'dmspxx_vih'
	'viE_dmsp': tv_name = 'dmspxx_viE'
	'mlat_dmsp': tv_name = 'dmspxx_mlat'
	'mlt_dmsp': tv_name = 'dmspxx_mlt'

	;;;;;;;;;;;; swarm quantities ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	'dmag_nec_swarm': tv_name = 'smx_dmag_nec'
	'vih_swarm': tv_name = 'smx_vih'
	'mlat_swarm': tv_name = 'smx_mlat'
	'mlt_swarm': tv_name = 'smx_mlt'

	;;;;;;;;;;;; single quantities, Solar wind or GBOs ;;;;;;;;;;;
	'kyoto_ae': tv_name = 'kyoto_ae'
	'kyoto_al': tv_name = 'kyoto_al'
	'kyoto_dst': tv_name = 'kyoto_dst'
	'pseudo_ae': tv_name = 'thg_idx_ae'
	'pseudo_al': tv_name = 'thg_idx_al'
	'omni_b_gsm': tv_name = 'omni_b_gsm'
	'omni_v_gsm': tv_name = 'omni_v_gsm'
	'omni_ni': tv_name = 'omni_ni'
	'omni_Pdyn': tv_name = 'omni_Pdyn'
	'omni_vxb': tv_name = 'omni_vxb'
	else: begin
		print, 'CHECK_DATATYPE: tv_Name No match!'
		tv_name = 'unknown'
		end
endcase

;;;;;;;;; data resulution
;;; mass data simple check
if strmatch(datatype, '*efs*') then begin
	resolution = 3.
	etype = 'efs'
endif
if strmatch(datatype, '*eff*') then begin
	resolution = 1./8
	etype = 'eff'
endif
if strmatch(datatype, '*efh*') then begin
	resolution = 1./128
	etype = 'efh'
endif
if strmatch(datatype, '*efs_rbsp*') then begin
	resolution = 11.
	etype = 'efs_rbsp'
endif
if strmatch(datatype, '*vsvy_rbsp*') then begin
	resolution = 0.0625
	etype = 'vsvy_rbsp'
endif

;;; other datatypes
case datatype of
	;;;;;;;;;;;;;;;;;;; THEMIS and RBSP quantities ;;;;;;;;;;;;;;;;;;;;
	'pos': resolution = 60.
	'pos_rbsp': resolution = 4.
	'fgs': resolution = 3.
	'fgs_rbsp': resolution = 4.
	'fgl': resolution = 0.25
	'fgl_rbsp': resolution = 1.
	'fgh': resolution = 1./128.
	'efs_rbsp': resolution = 11.
	'vperp_efs_rbsp': resolution = 11.
	'vperp_efw_rbsp': resolution = 11.
	'roi': resolution = 60.
	'mode': resolution = 60.
	'intEy': resolution = 3.
	'intEy_dsl': resolution = 3.
	'ns': resolution = 3 ; neutral sheet
	'efw_density': resolution = 11. ;; RBSP efw inferred electron density
	;;;; moments
	'Blobe': resolution = 3
	'beta': resolution = 3
	'ni': resolution = 3
	'ne': resolution = 3
	'vi': resolution = 3
	've': resolution = 3
	'viperp': resolution = 3
	'veperp': resolution = 3
	'vipar': resolution = 3
	'vepar': resolution = 3
	'vixy_infer': resolution = 3
	'Pth': resolution = 3
	'Pall': resolution = 3
	'Pb_fgs': resolution = 3
	'Pttl_fgs': resolution = 3
	'Tall': resolution = 3
	'vxb': resolution = 3
	'vixb': resolution = 3
	'vixb_dsl': resolution = 3
	'vexb': resolution = 3
	'vexb_dsl': resolution = 3
	;;;; rbsp moments
	'np_hope_rbsp': resolution = 11.
	'Tp_hope_rbsp': resolution = 11.
	'Pp_hope_rbsp': resolution = 11.
	'ni_hope_rbsp': resolution = 11.
	'Ti_hope_rbsp': resolution = 11.
	'Pi_hope_rbsp': resolution = 11.
	'ne_hope_rbsp': resolution = 11.
	'Te_hope_rbsp': resolution = 11.
	'Pe_hope_rbsp': resolution = 11.
	'Pth_hope_rbsp': resolution = 11.
	'Pall_hope_rbsp': resolution = 11.
	'ni_rbsp': resolution = 11.
	'Ti_rbsp': resolution = 11.
	'np_rbsp': resolution = 11.
	'Tp_rbsp': resolution = 11.
	'ne_rbsp': resolution = 11.
	'Te_rbsp': resolution = 11.
	'Pth_rbsp': resolution = 11.
	'Pall_rbsp': resolution = 11.
	;;;; rbsp spectra
	'mageis_p': resolution = 11.
	'mageis_e': resolution = 11.
	'rept_p': resolution = 11.
	'rept_e': resolution = 11.
	'hope_sa_p': resolution = 11.
	'hope_sa_e': resolution = 11.

	;;;;;;;;;;;; MMS quantities ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	'fgs_mms': resolution = 3.
	'fgl_mms': resolution = 0.0625
	'pos_mms': resolution = 30.

	;;;;;;;;;;;; DMSP quantities ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	'dmag_sc_dmsp': resolution = 1.
	'dmag_nec_dmsp': resolution = 1.
	'dmagigrf_nec_dmsp': resolution = 1.
	'vih_dmsp': resolution = 1.
	'viE_dmsp': resolution = 1.
	'mlat_dmsp': resolution = 1.
	'mlt_dmsp': resolution = 1.

	;;;;;;;;;;;; swarm quantities ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	'dmag_nec_swarm': resolution = 1.
	'vih_swarm': resolution = 0.5
	'mlat_swarm': resolution = 1.
	'mlt_swarm': resolution = 1.

	;;;;;;;;;;;; single quantities, Solar wind or GBOs ;;;;;;;;;;;
	'kyoto_ae': resolution = 60.
	'kyoto_al': resolution = 60.
	'kyoto_dst': resolution = 3600.
	'pseudo_ae': resolution = 60.
	'pseudo_al': resolution = 60.
	'omni_b_gsm': resolution = 60.
	'omni_v_gsm': resolution = 60.
	'omni_ni': resolution = 60.
	'omni_Pdyn': resolution = 60.
	'omni_vxb': resolution = 60.
	else: begin
			if ~keyword_set(resolution) then begin
				print, 'CHECK_DATATYPE: Resolution no match!'
				resolution = 0.
			endif
		end
endcase

;;;;; dimension
case datatype of
	;;;;;;;;;;;;;;;;;;; THEMIS and RBSP quantities ;;;;;;;;;;;;;;;;;;;;
	;;;; normal quantities
	'pos': dim = 3
	'pos_rbsp': dim = 3
	'fgs': dim = 3
	'fgs_rbsp': dim = 3
	'fgh': dim = 3
	'fgl': dim = 3
	'fgl_rbsp': dim = 3
	'Blobe': dim = 1
	'beta': dim = 1
	'ni': dim = 1
	'ne': dim = 1
	'vi': dim = 3
	'viperp': dim = 3
	'vipar': dim = 3
	've': dim = 3
	'veperp': dim = 3
	'vepar': dim = 3
	'vixy_infer': dim = 3
	'vxb': dim = 3
	'vixb': dim = 3
	'vixb_dsl': dim = 3
	'vexb': dim = 3
	'vexb_dsl': dim = 3
	'Pth': dim = 3
	'Pall': dim = 3
	'Pb_fgs': dim = 3
	'Pttl_fgs': dim = 3
	'Tall': dim = 3
	'ns': dim = 1
	'roi': dim = 1
	'mode': dim = 1
	;;;; rbsp moments
	'np_hope_rbsp': dim = 1
	'Tp_hope_rbsp': dim = 1
	'Pp_hope_rbsp': dim = 1
	'ni_hope_rbsp': dim = 1
	'Ti_hope_rbsp': dim = 1
	'Pi_hope_rbsp': dim = 1
	'ne_hope_rbsp': dim = 1
	'Te_hope_rbsp': dim = 1
	'Pe_hope_rbsp': dim = 1
	'Pth_hope_rbsp': dim = 1
	'Pall_hope_rbsp': dim = 1
	'ni_rbsp': dim = 1
	'Ti_rbsp': dim = 1
	'np_rbsp': dim = 1
	'Tp_rbsp': dim = 1
	'ne_rbsp': dim = 1
	'Te_rbsp': dim = 1
	'Pth_rbsp': dim = 1
	'Pall_rbsp': dim = 3
	;;;; rbsp spectra
	'mageis_p': dim = 31
	'mageis_e': dim = 25
	'rept_p': dim = 8
	'rept_e': dim = 12
	'hope_sa_p': dim = 72
	'hope_sa_e': dim = 9 ;; note to set reduce, 9 for burst, 36 for normal
	;;; Electric field quantities
	'efs_rbsp': dim = 3
	'vsvy_rbsp': dim = 6
	'efs_dsl': dim = 3
	'efs_dot0_dsl': dim = 3
	'efs_gsm': dim = 3
	'eff_dsl': dim = 3
	'eff_dot0_dsl': dim = 3
	'vperp_efs': dim = 3
	'vperp_eff': dim = 3
	'vperp_efs_rbsp': dim = 3
	'vperp_efw_rbsp': dim = 3
	'intEy': dim = 1
	'intEy_dsl': dim = 1
	'efw_density': dim = 1 ;; RBSP efw inferred electron density

	;;;;;;;;;;;; MMS quantities ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	'fgs_mms': dim = 3
	'fgl_mms': dim = 3
	'pos_mms': dim = 3

	;;;;;;;;;;;; DMSP quantities ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	'dmag_sc_dmsp': dim = 3 ;; spacecraft frame
	'dmag_nec_dmsp': dim = 3 ;; N, E, C
	'dmagigrf_nec_dmsp': dim = 3 ;; N, E, C
	'vih_dmsp': dim = 1 ;; perp-track component
	'viE_dmsp': dim = 1 ;; eastward component
	'mlat_dmsp': dim = 1
	'mlt_dmsp': dim = 1

	;;;;;;;;;;;; swarm quantities ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	'dmag_nec_swarm': dim = 3
	'vih_swarm': dim = 2
	'mlat_swarm': dim = 1
	'mlt_swarm': dim = 1

	;;;;;;;;;;;; single quantities, Solar wind or GBOs ;;;;;;;;;;;
	'kyoto_ae': dim = 1
	'kyoto_al': dim = 1
	'kyoto_dst': dim = 1
	'pseudo_ae': dim = 1
	'pseudo_al': dim = 1
	'omni_b_gsm': dim = 3
	'omni_v_gsm': dim = 3
	'omni_ni': dim = 1
	'omni_Pdyn': dim = 1
	'omni_vxb': dim = 3
	else: begin
			print, 'CHECK_DATATYPE: Dimension no match!'
			dim = 0
		end
endcase

case 1 of
strmatch(datatype, '*_rbsp') or strmatch(datatype, '*_dmsp'): file_prefix = strmid(datatype, 0, strlen(datatype)-5)
strmatch(datatype, '*_swarm'): file_prefix = strmid(datatype, 0, strlen(datatype)-6)
strmatch(datatype, '*_mms'): file_prefix = strmid(datatype, 0, strlen(datatype)-4)
else: file_prefix = datatype
endcase

;;;;;;;;; type of quantities
single_quantities = ['kyoto_ae', 'kyoto_al', 'kyoto_dst', 'pseudo_ae', 'pseudo_al', 'omni_b_gsm', 'omni_v_gsm', 'omni_ni', 'omni_Pdyn', 'omni_vxb']
spec_quantities = ['mageis_p', 'mageis_e']
efi_quantities = ['efs_dsl', 'efs_dot0_dsl', 'efs_gsm', 'eff_dsl', 'eff_dot0_dsl', 'intEy', 'intEy_dsl', 'efw', 'efs_rbsp', 'vsvy_rbsp', 'vperp_efs', 'vperp_efs_rbsp', 'vperp_efw', 'vperp_efw_rbsp']
dsl_quantities = ['efs_dsl', 'efs_dot0_dsl', 'eff_dsl', 'eff_dot0_dsl', 'intEy_dsl']

if strcmp_or(datatype, single_quantities) then single = 1 else single = 0
if strcmp_or(datatype, spec_quantities) then spec = 1 else spec = 0
if strcmp_or(datatype, efi_quantities) then efi = 1
if strcmp_or(datatype, dsl_quantities) then dsl = 1 else dsl = 0

return, tv_name
end
