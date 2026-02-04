pro load_bin_data, trange = trange, probes = probes, datatype = datatype, tclip = tclip, datafolder = datafolder, file_prefix = file_prefix_in, suffix = suffix, typecode = typecode, rtrange = rtrange
;; load data directly from pre-stored folder
; datatype: satellite location (GSM): pos, fgs, ae
; typecode: datatype, float or double (5)
; file_prefix: set if the file prefix is different than datatype
; if tclip is set then there will be subscribe '_tclip'

if ~ keyword_set(suffix) then suffix = '' ;; to tell apart pre-existing tvnames
if ~ keyword_set(probes) then begin
	probes = ['a','b','c','d','e']
endif
if ~ keyword_set(typecode) then typecode = 5

;;; tv name and dimension and whether single
tv_name = check_datatype(datatype, dim = dim, single = single, file_prefix = file_prefix_checked)+suffix
;;; single quantity no probes is needed, probes is set to ''
if single then probes = ''
;;; file prefix
if ~ keyword_set(file_prefix_in) then file_prefix = file_prefix_checked else file_prefix = file_prefix_in

trange = time_double(trange)
if ~ keyword_set(datafolder) then begin
  print, 'LOAD_DATA: no datafolder specified.'
  print, 'LOAD_DATA: type of data: '+datatype
  stop
endif

for p = 0, n_elements(probes)-1 do begin
	probe = probes(p)
	case 1 of
	strcmp_or(probe, ['a','b','c','d','e','r','s']): strput, tv_name, probe, 2 ;;; THEMIS, RBSP, or Swarm
	strcmp_or(probe, ['1','2','3','4']): begin
		if strmatch(datatype, '*mms*') then begin
			strput, tv_name, probe, 3 ;;; MMS
		endif else begin
			strput, tv_name, probe, 1 ;;; cluster
		endelse
		end
	strcmp_or(probe, ['09','10','11','12','13','14','15','16','17','18','19']): strput, tv_name, probe, 4 ;;; DMSP
	else: print, 'This probe '+probe+' is not supported or there is no probe set (treating as aux variable)!'
	endcase
		
	;;; in case of causing no data loaded but using previous data loaded, first delete the regarding tplot variable
	del_data, tv_name
	
	t_0 = trange(0)
	t_end = trange(1)
	
	start_day = time_double(time_string(t_0, format=6, precision=-3))
	end_day = time_double(time_string(t_end, format=6, precision=-3))
	day = start_day
	temp_time = [0.]
	temp_data = dblarr(1,dim)
	while day le end_day do begin
		day_str = time_string(day, format=6, precision=-3)
		year = strmid(day_str, 0, 4)
	    ufilename = file_prefix+day_str
	    path = datafolder+'/'+year+'/'+ufilename+probe+'.dat'
	    info = file_info(path)
	    if info.exists eq 0 then begin
	      print, 'LOAD_DATA: '+path+' does not exist!'
	      day = day+24*3600.
	      continue
	    endif else begin
	      indata=read_binary(path, data_type=typecode)
	      full_l=n_elements(indata)
	      data=dblarr(dim+1,full_l/(dim+1))
	      ind=indgen(full_l/(dim+1),/long)*(dim+1)
	      for i=0, dim do begin
	        data(i,*)=indata(ind)
	        ind=ind+1
	      endfor
	      temp_time = [temp_time, transpose(data(0,*))]
	      temp_data = [temp_data, transpose(data(1:*,*))]
	      day = day+24*3600.
	    endelse
	endwhile
	if n_elements(temp_time) lt 2 then begin
	   print, 'LOAD_DATA: No data during this time range for probe '+probe+'!'
	   continue
	endif else begin
	   temp_time = temp_time(1:*)
	   temp_data = temp_data(1:*, *)
	   ;;; manage the overlapping data
		n_d = n_elements(temp_time)
		if n_d gt 1 then begin
			i_bad = where(temp_time(1:*)-temp_time(0:n_d-2) le 0., j_bad) 
			if j_bad gt 0 then begin
				i_sort = sort(temp_time)
				temp_time = temp_time(i_sort)
				temp_data = temp_data(i_sort, *)
				dif_t = temp_time(1:*)-temp_time(0:n_d-2)
				i_good = where(dif_t gt 0.)
				i_good = [0, i_good+1]
				temp_time = temp_time(i_good)
				temp_data = temp_data(i_good, *)
			endif
		endif
	    ;;; add attributes to data
	    if strmatch(tv_name, '*_gsm*') then begin
			cotrans_set_coord, dl, 'gsm'
		endif
	    store_data, tv_name, data = {x:temp_time, y:temp_data}, dl = dl
	endelse
	; tclip the data
	if keyword_set(tclip) then begin
	 del_data, tv_name+'_tclip'
	 time_clip, tv_name, t_0, t_end
	endif
endfor ; for of probes

end
