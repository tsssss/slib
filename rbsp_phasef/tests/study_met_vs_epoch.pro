;+
; EMFISIS data have MET, so let's see how MET relates to epoch.
; 
; No. MET is empty...
;-


emfisis_file = join_path([homedir(),'Downloads','rbsp-a_magnetometer_hires-gse_emfisis-L3_20121108_v1.3.4.cdf'])
cdf2tplot, emfisis_file
met = cdf_read_var('MET', filename=emfisis_file)

end