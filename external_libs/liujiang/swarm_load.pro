;+
; NAME:
;   SWARM_LOAD
;

;; Inputs: 
;;		probes: can be a, b, c, or _ (which means derived quantities from multiple swarm spacecraft, e.g., curlometer FAC)
;; 		level: must be a string, '1b', '2daily', or '2longterm', mostly useless, default is 1b
;; 		swarm_folder: the custom folder that has already got data stored. If not set, the program will automaticlly download data to the root data folder
;; 		no_download: will force no download, if swarm_folder set, automatically no download
;; 		resolution_new: the new custom resolution in seconds, the data will be interpolated/reduced to this higher/lower resolution
;; 		usrname, passwd: the username and password for the SWARM ftp site.
;; 		Seach [Marker] for the location to see all loaded raw names.
;; 		rtrange: the range for computing offset, now used only by velocity and electric field. Please choose the equator range for detrending (when velocity should by 0)
;;		flag_tii: value of tii flag, greater than this is set NaN.
;;		period_recdipole: the period of recomputing dipole axis direction, used by t89 (only when loading mag data), in seconds
;;		invariant: set this keyword to compute invariant latitude and longitude and mlt (takes time).
;;		sub_igrf: tell it to subtract IGRF to compute dmag
;; made by Jiang Liu, last updated 2018/11/6


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Dependent routine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function check_file, day_str_single, file_prefix, data_suffix, file_list = file_list, folder_local = folder_local

;; Inputs: See how SWARM_LOAD.pro calls this routine to see what the inputs mean.
;; Outputs:
;;	If no file is found, the return value will be ''
day_str_pre = day_str_single+'T??????_????????T??????'
day_str_aft = '????????T??????_'+day_str_single+'T??????'
day_strs_try = [day_str_pre, day_str_aft]

filenames_match = ''
for i_try = 0, n_elements(day_strs_try)-1 do begin
	day_str = day_strs_try[i_try]
	ufilename = file_prefix+day_str
	file_checkname = ufilename+'_*'+data_suffix

	if keyword_set(file_list) then begin
		i_match = where(strmatch(file_list, file_checkname, /fold_case), n_match)
	endif else if keyword_set(folder_local) then begin
		filenames_match_wfolder = file_search(folder_local, file_checkname, /fold_case, count=n_match, /fully_qualify_path)
	endif else begin
		message, 'Need to set one of the keywords. Check code.'
	endelse

	if n_match gt 0 then begin
		if keyword_set(file_list) then begin
			filenames_match_this = file_list[i_match]
		endif else if keyword_set(folder_local) then begin
			filenames_match_this = file_basename(filenames_match_wfolder)
		endif else begin
			message, 'Need to set one of the keywords. Check code.'
		endelse

		;;; remove matches for special kind of data
		if strcmp(day_str, day_str_aft) then begin
			i_bad = where(strmatch(filenames_match_this, '*T??????_????????T000000*'), n_bad)
			if n_bad gt 0 then begin
				filenames_match_this[i_bad] = ''
			endif
		endif

		filenames_match = [filenames_match, filenames_match_this]
	endif
endfor

;;;; remove bad matches
i_gm = where(~strcmp(filenames_match, ''), n_gm)
if n_gm gt 0 then begin
	filenames_match = filenames_match[i_gm]
endif else begin
	filenames_match = ''
	print, 'CHECK_FILE: There is no data found for day '+day_str_single+'.'
endelse

;;;; make the names unique
filenames_match_uniq = filenames_match[uniq(filenames_match, sort(filenames_match))]
return, filenames_match_uniq

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; END of main routine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main routine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro swarm_load, trange = trange, datatype = datatype, probes = probes, swarm_folder = swarm_folder_in, tclip = tclip, suffix = suffix, level = level_in, resolution_new = resolution_new, rtrange = rtrange, no_download = no_download, usrname = usrname_in, passwd = passwd_in, flag_tii = flag_tii, period_recdipole = period_recdipole_in, invariant = invariant, sub_igrf = sub_igrf

if keyword_set(usrname_in) then usrname = usrname_in else usrname = 'swarm0555'
if keyword_set(passwd_in) then passwd = passwd_in else passwd = 'othonwoo01'

;; specify the default server url for download
download_server = 'ftp://'+usrname+':'+passwd+'@swarm-diss.eo.esa.int/' ;; default server, for different quantities can set below
download = OBJ_NEW('IDLnetUrl')
download->setProperty,FTP_CONNECTION_MODE=0 ;; set to passive mode to avoid firewalls

if ~ keyword_set(suffix) then begin
	if keyword_set(resolution_new) then suffix = '_newres' else suffix = ''
endif
	
if size(level_in, /type) eq 0 then level = '1b' else level = level_in ;; for general use, but will be overode by the specific datatypes below. Mostly useless.
swarm_data_prefix = 'SW_OPER_' ;; overall prefix for most data, preliminary data will be changed

;;;;;;;;;;;;;;;;;; data discriptions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
time_name = 'Timestamp' ;; name for the time variable inside cdf
zvariable = 1 ;; whether the CDF has stored quantities in zvariables. This default is from MAG data


case 1 of
;;;; MAG 1 Hz data
strcmp(datatype, 'MAG', /fold): begin
	level = '1b'
	data_prefix = 'MAG'
	data_suffix1 = '_LR_1B_' ;; the suffix before time in the file name
	data_suffix_online = '.CDF.ZIP' ;; for the zip file, everyting after time
	data_suffix_local = '_MDR_MAG_LR.cdf' ;; for the unziped file, everything after time
	folder_pref = '/Level'+level+'/Current/MAGx_LR/' ;; for local directory
	folder_pref_remote = '/Level'+level+'/Latest_baselines/MAGx_LR/' ;; for the download server
	if_year = 0
	in_names = ['Latitude', 'Longitude', 'Radius', 'B_VFM', 'B_NEC'] ;; names in the cdf to be stored
	out_names = ['smx_lat', 'smx_lon', 'smx_r', 'smx_mag_vfm', 'smx_mag_nec']+suffix
	res_orig = 1. ;; in seconds
	alt_aurora = 110. ;; to project location along field lines, in km

	if keyword_set(period_recdipole_in) then period_recdipole = period_recdipole_in else period_recdipole = 60.
	end

;;;; Field aligned currents. Resolution is 1 sec for single probe as well as curlometer result.
strcmp(datatype, 'FAC', /fold): begin
	level = '2daily'
	data_prefix = 'FAC'
	data_suffix1 = 'TMS_2F_' ;; the suffix before time in the file name
	data_suffix_online = '.ZIP' ;; for the zip file, everyting after time
	data_suffix_local = '.cdf' ;; for the unziped file, everything after time
	folder_pref = '/Level'+level+'/Current/FAC/TMS/' ;; for local directory
	folder_pref_remote = '/Level'+level+'/Latest_baselines/FAC/TMS/' ;; for the download server
	if_year = 0
	in_names = ['Latitude', 'Longitude', 'Radius', 'IRC', 'FAC', 'IRC_Error', 'FAC_Error', 'Flags'] ;; names in the cdf to be stored
	out_names = ['smx_lat', 'smx_lon', 'smx_r', 'smx_irc', 'smx_fac', 'smx_irc_err', 'smx_fac_err', 'smx_flagfac']+suffix
	res_orig = 1. ;; in seconds
	end

;;;; Plasma data, 0.5s resolution (for now all ion quantities are 0)
strcmp(datatype, 'EFI', /fold): begin
	level = '1b'
	data_prefix = 'EFI'
	data_suffix1 = '_PL_1B_' ;; the suffix before time in the file name
	data_suffix_online = '.ZIP' ;; for the zip file, everyting after time
	data_suffix_local = '_MDR_EFI_PL.cdf' ;; for the unziped file, everything after time
	folder_pref = '/Level'+level+'/Current/EFIx_PL/' ;; for local directory
	folder_pref_remote = '/Level'+level+'/Latest_baselines/EFIx_PL/'  ;; for the download server
	if_year = 0
	in_names = ['Latitude', 'Longitude', 'Radius', 'v_SC', 'v_ion', 'v_ion_error', 'E', 'E_error', 'n', 'n_error', 'T_ion', 'T_ion_error', 'T_elec', 'T_elec_error', 'v_ion_H'] ;; names in the cdf to be stored
	out_names = ['smx_lat', 'smx_lon', 'smx_r', 'smx_vsc', 'smx_vi', 'smx_vi_err', 'smx_efi', 'smx_efi_err', 'smx_density', 'smx_density_err', 'smx_tempi', 'smx_tempi_err', 'smx_tempe', 'smx_tempe_err', 'smx_vih']+suffix
	res_orig = 0.5 ;; in seconds
	end

;;;; Plasma data, PREL TII (preliminary data)
strcmp(datatype, 'PREL_TII', /fold): begin
	swarm_data_prefix = 'SW_PREL_' ;; overall prefix for most data, preliminary data will be changed
	level = '1b'
	data_prefix = 'EFI'
	data_suffix1 = '_TII1B_' ;; the suffix before time in the file name
	data_suffix_online = '.cdf.ZIP' ;; for the zip file, everyting after time
	data_suffix_local = '.cdf' ;; for the unziped file, everything after time
	folder_pref = '/Advanced/Plasma_Data/Provisional_Plasma_dataset/Thermal_Ion_Imagers_Data/' ;; for local directory
	folder_pref_remote = folder_pref ;; for the download server
	if_year = 0
	;;;; Note: Flags_TII must be the first to be stored, or cannot mark flags with NaN.
	in_names = ['Flags_TII', 'latitude', 'longitude', 'radius', 'v_SC', 'v_ion', 'E', 'T_ion', 'v_ion_H'] ;; names in the cdf to be stored
	out_names = ['smx_flagtii', 'smx_lat', 'smx_lon', 'smx_r', 'smx_vsc', 'smx_vi', 'smx_efi', 'smx_tempi', 'smx_vih']+suffix ;;; vih: second component is the cross-track flow
	res_orig = 0.5 ;; in seconds

	;;;; the flag of TII, values equal to or larger than this will be marked NaN.
	if keyword_set(flag_tii) then value_flag_tii = flag_tii else value_flag_tii = 25 ;; Knudson suggested 20; set a big value to disable.
	end

;;;;; Plasma data, EXPT TII (expert data)
strcmp(datatype, 'EXPT_TII', /fold): begin
	swarm_data_prefix = 'SW_EXPT_' ;; overall prefix for most data, preliminary data will be changed
	level = '1b'
	data_prefix = 'EFI'
	data_suffix1 = '_TIICT_' ;; the suffix before time in the file name
	data_suffix_online = '.cdf.ZIP' ;; for the zip file, everyting after time
	data_suffix_local = '.cdf' ;; for the unziped file, everything after time
	folder_pref = '/Advanced/Plasma_Data/2Hz_TII_Cross-track_Dataset/' ;; for local directory
	folder_pref_remote = folder_pref ;; for the download server
	if_year = 0
	;;;; Note: Flags_TII must be the first to be stored, or cannot mark flags with NaN.
	in_names = ['qdlat', 'mlt', 'viy', 'ex', 'qy'] ;; names in the cdf to be stored
	out_names = ['smx_qdlat', 'smx_mlt', 'smx_viy', 'smx_ex', 'smx_qy']+suffix
	res_orig = 0.5 ;; in seconds

	;;;; the flag of TII, values equal to or larger than this will be marked NaN.
	if keyword_set(flag_tii) then value_flag_tii = flag_tii else value_flag_tii = 1 ;; Greater or equal to this value is good. See the hand book to see what the values mean (-1 - 2)
	end


else: message, 'This datatype is not supported!'
endcase


;;;;;;;;;;;;;;;;; end of data discriptions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;; Some constants depending on settings
;;; the length of file until the end of time
strlen_ufilename = strlen(swarm_data_prefix+data_prefix+'A'+data_suffix1+'????????T??????_????????T??????')
strlen_ufilename_wversion = strlen_ufilename+strlen('_0505')


trange = time_double(trange)
if keyword_set(swarm_folder_in) then begin
	swarm_folder = swarm_folder_in
endif else begin
	print, 'SWARM_LOAD: no swarm_folder specified. Will use the defaut data folder'
	swarm_folder = root_data_dir()+'/swarm'
endelse


for p = 0, n_elements(probes)-1 do begin
	probe = strlowcase(probes(p))
	probe_up = strupcase(probe)

	if strcmp(probe, '_') then begin
		case strupcase(datatype) of
		'FAC': folder_probe = '/Sat_AC'
		else: message, 'Type not supported yet!'
		endcase
	endif else folder_probe = '/Sat_'+probe_up
	datafolder = swarm_folder+folder_pref+folder_probe
	downloadfolder_up = download_server+folder_pref_remote+folder_probe
	file_prefix = swarm_data_prefix+data_prefix+probe_up+data_suffix1


	for i = 0, n_elements(out_names)-1 do begin
		name_this = out_names[i]
		strput, name_this, probe, 2
		out_names[i] = name_this
	endfor

	;; in case of causing no data loaded but using previous data loaded, first delete the regarding tplot variable
	del_data, in_names
	del_data, in_names+'_RAW'
	del_data, out_names
	
	t_0 = trange[0]
	t_end = trange[1]
	
	start_day = time_double(time_string(t_0, format=6, precision=-3))
	end_day = time_double(time_string(t_end, format=6, precision=-3))
	day = start_day

	;;;;; check server first, to know whether there are files not downloaded.
	if ~keyword_set(no_download) and ~if_year then begin
		print, 'SWARM_LOAD: Checking remote data.'
		downloadfolder = downloadfolder_up+'/'
		file_list = download->GetFtpDirList(URL=downloadfolder, /short)
	endif


	;; repeat for days
	while day le end_day do begin
		day_str_single = time_string(day, format=6, precision=-3)
		year = strmid(day_str_single, 0, 4)
		folder_local = datafolder+'/'+year+'/'

		;;;;; check server first, to know whether there are files not downloaded.
		if ~keyword_set(no_download) then begin
			if if_year then begin
				print, 'SWARM_LOAD: Checking remote data for day '+day_str_single+'.'
				downloadfolder = downloadfolder_up+'/'+year+'/'
				file_list = download->GetFtpDirList(URL=downloadfolder, /short)
			endif

			filenames_match_remote = check_file(day_str_single, file_prefix, data_suffix_online, file_list = file_list)
			if strcmp(filenames_match_remote[0], '') then print, 'SWARM_LOAD: There is no remote data found for day '+day_str_single+'.'

		endif else filenames_match_remote = '' ;;; if of whether no_download is set


		;;;; check in local folder if the file exists. filenames_match: do not need to worry about order; the data will be sorted based on time later.
		filenames_match_local = check_file(day_str_single, file_prefix, data_suffix_local, folder_local = folder_local)
		if strcmp(filenames_match_local[0], '') then print, 'SWARM_LOAD: There is no local data found for day '+day_str_single+'.'


	    if strcmp(filenames_match_local[0], '') and strcmp(filenames_match_remote[0], '') then begin
			print, 'SWARM_LOAD: '+file_prefix+' data for day '+day_str_single+' does not exist in folder '+folder_local+'!'
	    	day = day+24*3600.
	    	continue
	    endif else begin

			if ~strcmp(filenames_match_remote[0], '') then begin
				;;;; download data if new data is available (always overwrite local data with new version of data)

				for i_fr = 0, n_elements(filenames_match_remote)-1 do begin

					if total(strcmp(filenames_match_remote[i_fr], filenames_match_local, strlen_ufilename_wversion, /fold)) lt 1 then begin
						filename_download = filenames_match_remote[i_fr]
						file_checkname = strmid(filename_download, 0, strlen_ufilename)+'_*'+data_suffix_local

						path_download = folder_local+filename_download
						url_download = downloadfolder+filename_download
						if ~file_test(folder_local, /directory) then begin
							file_mkdir, folder_local
						endif
						;; download data
						print, 'SWARM_LOAD: Downloading from '+downloadfolder
						full_path = download->Get(FILENAME=path_download, URL=url_download)
						print, 'SWARM_LOAD: data downloaded to '+full_path

						;;; unzip data if the downloaded data is zipped.
						if strmatch(path_download, '*.zip', /fold_case) then begin
							file_unzip, path_download, files = paths_unzipped
							print, 'SWARM_LOAD: File '+path_download+' has been unzipped.'
							i_match = where(strmatch(paths_unzipped, '*'+file_checkname, /fold_case), n_match)
							if n_match gt 0 then begin
								file_downuse = file_basename(paths_unzipped[i_match[-1]])
								;; delete the zip file 
								file_delete, path_download
								;; deleter other unzipped files
								i_notmatch = where(~strmatch(paths_unzipped, '*'+file_checkname, /fold_case), n_notmatch)
								if n_notmatch gt 0 then file_delete, paths_unzipped[i_notmatch]
								if n_match gt 1 then file_delete, paths_unzipped[i_match[0:-2]]
								print, 'SWARM_LOAD: the ZIP file and other unwanted files have been deleted.'
							endif else begin
								message, 'No matching file in the unzipped files!'
							endelse
						endif else begin
							file_downuse = file_basename(path_download)
						endelse

						;;;;; Now compare the new file with old ones, if same time range, delete the old one.
						i_match = where(strcmp(filenames_match_local, file_downuse, strlen_ufilename, /fold), n_match)
						if n_match gt 0 then begin
							file_delete, filenames_match_local[i_match]
							print, 'SWARM_LOAD: Older version files have been deleted.'
						endif
					endif ;;; if of whether there is a file of the same name so will not download.

				endfor ;;; for of all remote files found.
			endif ;;; if of existing remote files


			;;;;;;; Re-check the local files to ge the final file list to load
			filenames_match = check_file(day_str_single, file_prefix, data_suffix_local, folder_local = folder_local)
			filenames_match = filenames_match[sort(filenames_match)]
			filenames_match_pre = strmid(filenames_match, 0, strlen_ufilename)
			i_ufile = uniq(filenames_match_pre)
			files_load = filenames_match[i_ufile]

			;;;; load data
			for i_f = 0, n_elements(files_load)-1 do begin
				path_load = folder_local+files_load[i_f]

				case 1 of
				strmatch(path_load, '*.cdf', /fold_case) or strmatch(path_load, '*.dbl', /fold_case): begin ;;; load CDF file
					cdf2tplot_lj_bottom, path_load, outnames = varnames_raw, zvariable = zvariable

					;;; stop here to check names [Marker]
					;;stop
					;if strcmp(datatype, 'expt_tii', /fold) then stop


					i_timename = where(strcmp(varnames_raw, time_name+'_RAW', /fold_case), n_timename)
					if n_timename gt 0 then timename_raw = varnames_raw[i_timename[0]] else message, 'No time name found; cannot proceed!'
					get_data, timename_raw, data = timedata

					;;; translate the time data into time_double
					case 1 of
					strcmp(timedata.type, 'CDF_EPOCH', /fold_case): begin
						cdf_epoch, timedata.data, yr, mo, dy, hr, mn, sec, milli, /break
						time_strt = {year:yr, month:mo, date:dy, hour:hr, min:mn, sec:sec, fsec:milli/1000d, tdiff:0}
						time = time_double(time_strt) 
						end
					strcmp(timedata.type, 'CDF_DOUBLE', /fold) and strmatch(datatype, '*_TII', /fold): begin
						time = timedata.data+time_double('2000 1 1')
						end
					else: message, 'This type of time is not supported yet!'
					endcase

					;;; make raw tvnames into usable tvnames
					for i_name = 0, n_elements(in_names)-1 do begin
						if tv_exist(in_names[i_name]+'_RAW') then begin
							get_data, in_names[i_name]+'_RAW', data = data_strt
							if n_elements(time) eq n_elements(data_strt.data[0,*]) then store_data, in_names[i_name], data = {x:transpose(time), y:transpose(data_strt.data)} else message, 'Time and data dimensions do not match! Check what happened.'
						endif else begin
							print, 'SWARM_LOAD: The tvname '+in_names[i_name]+' does not have raw data!'
							;;;; some exceptions here (in these cases, do not stop)
							if ~strcmp_or(in_names[i_name], ['ex', 'qy']) then stop
						endelse
					endfor

					del_data, varnames_raw ;; delete all raw names for faster run.
					end

				else: message, 'This file type for loading is not supported yet!'
				endcase

				;;;;; store all the data
				for i = 0, n_elements(in_names)-1 do begin
					;;;;;; Cut the data to contain only this day's data (because the EXPT_TII data often go across two days)
					time_clip, in_names[i], day, day+24*3600., newname = in_names[i]

					get_data, in_names[i], t, data, v, limits = limits, dlimits = dlimits 
					;; special treatement for 3d quantities
					if n_elements(size(data, /dim)) eq 3 then begin
						get_data, in_names[i], data = datastruct
						v = datastruct.v2
						v_angle = datastruct.v1
					endif

					;;; flag NaN points for too big values
					i_bad = where(abs(data) gt 1e30, n_bad)
					if n_bad gt 0 then begin
						data[i_bad] = !values.f_nan
					endif
					i_badv = where(abs(v) gt 1e30, n_badv)
					if n_badv gt 0 then begin
						v[i_badv] = !values.f_nan
					endif

					;; reorder v, in case it is a single array
					if ~((n_elements(v) eq 1) and (v[0] eq 0)) then begin
						data_dim1 = n_elements(data[*,0])
						data_dim2 = n_elements(data[0,*])
						v_dim1 = n_elements(v[*,0])
						v_dim2 = n_elements(v[0,*])

						if (data_dim1 ne v_dim1) or (data_dim2 ne v_dim2) then begin
							if v_dim1 eq data_dim2 then begin
								v = rebin(transpose(v), data_dim1, v_dim1)
							endif else begin
								if v_dim2 eq data_dim2 then begin
									v = rebin(v, data_dim1, v_dim2)
								endif else begin
									message, 'Warning: please check v'
								endelse
							endelse
						endif
					endif

					;;; make the data to be the same resolution of the asked resolution.
					if keyword_set(resolution_new) then begin
						if resolution_new ne res_orig then begin
							;;; create the new time series, but be careful of data gaps.
							tranges_cont = split_range(t, max([3*res_orig, 2*resolution_new]))
							time_new = 0d
							for i_ranges = 0, n_elements(tranges_cont[0,*])-1 do begin
								trange_cont = tranges_cont[*,i_ranges]
								times_insert = linspace(trange_cont[0], trange_cont[1], increment = resolution_new)
								time_new = [time_new, times_insert]
							endfor
							time_new = time_new[1:*]

							;;; interpolate data
							data_new = fltarr(n_elements(time_new), n_elements(data[0,*]))
							for i_dim = 0, n_elements(data[0,*])-1 do begin
								data_this = data[*,i_dim]
								data_this_new = interpol(data_this, t, time_new)
								data_new[*,i_dim] = data_this_new
							endfor
							type_data = size(data, /type)
							data = fix(data_new, type = type_data)

							;;; interpolate v, which has been rebined the same dimension as data
							if keyword_set(v) then begin
								v_new = fltarr(n_elements(time_new), n_elements(v[0,*]))
								for i_dim = 0, n_elements(v[0,*])-1 do begin
									v_this = v[i_dim,*]
									v_this_new = interpol(v_this, t, time_new)
									v_new[i_dim,*] = v_this_new
								endfor
								type_v = size(v, /type)
								v = fix(v_new, type = type_v)
							endif
							
							;;; v_angle need not to be interpolated because it is a single array (for the case of RBSP, for SWARM, need to check)
							;;; replace output time with new time
							t = time_new
						endif else begin
							message, 'A higher resolution is not supported yet!'
						endelse ;; else of resolution_new higher or lower than the original resolution
					endif ;; if of whether resolution_new is set


					;;;;;; Store the new data
					if ~tv_exist(out_names[i]) then begin
						if n_elements(size(data, /dim)) eq 3 then begin
							data_store = {x:t, y:data, v1:v_angle, v2:v}
						endif else begin
							if (n_elements(v) eq 1) and (v[0] eq 0) then data_store = {x:t, y:data} else data_store = {x:t, y:data, v:v}
						endelse
						store_data, out_names[i], data = data_store, limits = limits, dlimits = dlimits 

					endif else begin
						get_data, out_names[i], t_old, data_old, v_old
						if n_elements(size(data, /dim)) eq 3 then begin
							get_data, out_names[i], data = datastruct_old
							v1_old = datastruct_old.v1
							v2_old = datastruct_old.v2
							data_store = {x:[t_old, t], y:[data_old, data], v1:v1_old, v2:[v2_old, v]}
						endif else begin
							if (n_elements(v_old) eq 1) and (v_old[0] eq 0) then data_store = {x:[t_old, t], y:[data_old, data]} else data_store = {x:[t_old, t], y:[data_old, data], v:[v_old, v]}
						endelse
						store_data, out_names[i], data = data_store, limits = limits, dlimits = dlimits 
					endelse
				endfor ;; for of i, in names

			endfor ;;; for of i_f, all files of this day

	    	day = day+24*3600. ;;; this is here instead of outside because in the if part this is already there.
	    endelse
	endwhile


	;;;;;; After loading all the data, manage data
	for i = 0, n_elements(out_names)-1 do begin
		if tv_exist(out_names[i]) then begin

	   		;;; manage the overlapping or wrong ordered data
	   		get_data, out_names[i], temp_time, temp_data, temp_v, limits = limits, dlimits = dlimits 
			if n_elements(size(temp_data, /dim)) eq 3 then begin
				get_data, out_names[i], data = temp_datastruct
				temp_v_angle = temp_datastruct.v1
				temp_v = temp_datastruct.v2
			endif
	   		n_d = n_elements(temp_time)
	   		if n_d gt 1 then begin
	   			i_bad = where(temp_time(1:*)-temp_time(0:n_d-2) le 0., j_bad) 
	   			if j_bad gt 0 then begin
	   				i_sort = sort(temp_time)
	   				temp_time = temp_time(i_sort)
	   				temp_data = temp_data(i_sort, *, *, *)
	   				dif_t = temp_time(1:*)-temp_time(0:n_d-2)
	   				i_good = where(dif_t gt 0.)
	   				i_good = [0, i_good+1]
	   				temp_time = temp_time(i_good)
	   				temp_data = temp_data(i_good, *, *, *)
					if ~((n_elements(temp_v) eq 1) and (temp_v[0] eq 0)) then begin
						temp_v = temp_v(i_sort, *, *, *)
						temp_v = temp_v(i_good, *, *, *)
					endif
	   			endif
	   		endif

			;;; store and cut data
			if n_elements(size(temp_data, /dim)) eq 3 then begin
				data_store = {x:temp_time, y:temp_data, v1:temp_v_angle, v2:temp_v}
			endif else begin
				if (n_elements(temp_v) eq 1) and (temp_v[0] eq 0) then begin
					data_store = {x:temp_time, y:temp_data}
				endif else begin
					if n_elements(temp_v[*,0]) ne n_elements(temp_time) then begin
						;; deal with the case when v has only one time point
						temp_v = rebin(temp_v[0,*], n_elements(temp_time), n_elements(temp_v[0,*]))
					endif
					data_store = {x:temp_time, y:temp_data, v:temp_v}
				endelse
			endelse
	   		store_data, out_names[i], data = data_store, limits = limits, dlimits = dlimits 



			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; special treatments for different types of data ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			;;;;;;;;;; compute magnetic latitude, longitude, and mlt ;;;;;;;;;;;;;;;
			if tv_exist('sm'+probe+'_lat') and tv_exist('sm'+probe+'_lon') and keyword_set(invariant) then begin
				get_data, 'sm'+probe+'_lat', t_lat, lat
				get_data, 'sm'+probe+'_lon', t_lon, lon
				mlt = transpose(latlont2mlt(transpose(t_lat), lat = transpose(lat), lon = transpose(lon), mlat = mlat, mlon = mlon))
				mlat = transpose(mlat) & mlon = transpose(mlon)
				store_data, 'sm'+probe+'_mlat', data = {x:t_lat, y:mlat} ;; -90 to 90
				store_data, 'sm'+probe+'_mlon', data = {x:t_lat, y:mlon} ;; -180 to -180
				store_data, 'sm'+probe+'_mlt', data = {x:t_lat, y:mlt} ;; 0 to 24
				if keyword_set(tclip) then begin
					del_data, 'sm'+probe+'_mlat_tclip'
					del_data, 'sm'+probe+'_mlon_tclip'
					del_data, 'sm'+probe+'_mlt_tclip'
					time_clip, 'sm'+probe+'_mlat', t_0, t_end
					time_clip, 'sm'+probe+'_mlon', t_0, t_end
					time_clip, 'sm'+probe+'_mlt', t_0, t_end
				endif
			endif

			;;;;;;;;;; Actions for magnetic field data ;;;;;;;;;;;;;;;;;
			if strmatch(out_names[i], 'sm'+probe+'_mag_nec') and tv_exist('sm'+probe+'_lat') and tv_exist('sm'+probe+'_lon') and tv_exist('sm'+probe+'_r') then begin
				get_data, out_names[i], t_mag, data_mag
				get_data, 'sm'+probe+'_lat', t_nouse, lat
				get_data, 'sm'+probe+'_lon', t_nouse, lon
				get_data, 'sm'+probe+'_r', t_nouse, r_sc
				r_sc = r_sc/6371000. ;; change m to RE

				;;;;;;;;;;;;;;;;;; Subtract IGRF from the mag field ;;;;;;;;;;
				if keyword_set(sub_igrf) or keyword_set(period_recdipole_in) then begin
					x_geo = r_sc*cos(lat*!pi/180.)*cos(lon*!pi/180.)
					y_geo = r_sc*cos(lat*!pi/180.)*sin(lon*!pi/180.)
					z_geo = r_sc*sin(lat*!pi/180.)
					store_data, 'sm'+probe+'_pos_geo', data = {x:t_mag, y:[[x_geo],[y_geo],[z_geo]]}
					cotrans, 'sm'+probe+'_pos_geo', 'sm'+probe+'_pos_gei', /geo2gei
					cotrans, 'sm'+probe+'_pos_gei', 'sm'+probe+'_pos_gse', /gei2gse
					cotrans, 'sm'+probe+'_pos_gse', 'sm'+probe+'_pos_gsm', /gse2gsm
					get_data, 'sm'+probe+'_pos_gsm', t_nouse, pos_gsm

					;;; get IGRF from T89
					mag_IGRF_gsm = t89(t_mag, pos_gsm, /igrf_only, /geopack_2008, period = period_recdipole) ;; pos must be in GSM

					;; transform GSM into NEC
					store_data, 'sm'+probe+'_igrf_gsm', data = {x:t_mag, y:mag_IGRF_gsm}
					cotrans, 'sm'+probe+'_igrf_gsm', 'sm'+probe+'_igrf_gse', /gsm2gse
					cotrans, 'sm'+probe+'_igrf_gse', 'sm'+probe+'_igrf_gei', /gse2gei
					cotrans, 'sm'+probe+'_igrf_gei', 'sm'+probe+'_igrf_geo', /gei2geo
					cotrans_geo2nec, 'sm'+probe+'_igrf_geo', 'sm'+probe+'_igrf_nec', lat = lat, lon = lon

					;; subtract igrf from mag data
					calc, "'sm"+probe+"_dmag_nec'='sm"+probe+"_mag_nec'-'sm"+probe+"_igrf_nec'"

					if keyword_set(tclip) then begin
						del_data, 'sm'+probe+'_dmag_nec_tclip'
						time_clip, 'sm'+probe+'_dmag_nec', t_0, t_end
					endif
					options, 'sm'+probe+'_dmag_nec*', ysubtitle = '[nT]', labels = ['dB!dN', 'dB!dE', 'dB!dC'], labflag = 1
				endif


				;;;;;;;;;;;;;;;; Compute the projected latitudes and longitudes based on b field
				r_sc = r_sc*6371 ;; RE to km
				mag_dir = normalize(data_mag, /array)
				i_neg = where(mag_dir[*,2] lt 0, n_neg)
				if n_neg gt 0 then begin
					mag_dir[i_neg,*] = -mag_dir[i_neg,*]
				endif
				inc = rebin(r_sc-(6371.+alt_aurora), n_elements(r_sc), 3)*mag_dir/rebin(mag_dir[*,2], n_elements(r_sc), 3)
				lon_inc = inc[*,1]/(6371.+alt_aurora)*180./!pi
				lat_inc = inc[*,0]/(6371.+alt_aurora)*180./!pi
				;;; Bz must be predominant to do the projection. 
				i_bzsmall = where(mag_dir[*,2] lt sqrt(mag_dir[*,0]^2+mag_dir[*,1]^2), n_bzsmall)
				if n_bzsmall gt 0 then begin
					lon_inc[i_bzsmall] = !values.f_nan
					lat_inc[i_bzsmall] = !values.f_nan
				endif

				store_data, 'sm'+probe+'_lat_inc', data = {x:t_mag, y:lat_inc}
				store_data, 'sm'+probe+'_lon_inc', data = {x:t_mag, y:lon_inc}
				store_data, 'sm'+probe+'_lat_bproj', data = {x:t_mag, y:lat+lat_inc}
				store_data, 'sm'+probe+'_lon_bproj', data = {x:t_mag, y:lon+lon_inc}
				if keyword_set(tclip) then begin
					del_data, 'sm'+probe+'_???_bproj_tclip'
					del_data, 'sm'+probe+'_???_inc_tclip'
					time_clip, 'sm'+probe+'_lat_inc', t_0, t_end
					time_clip, 'sm'+probe+'_lon_inc', t_0, t_end
					time_clip, 'sm'+probe+'_lat_bproj', t_0, t_end
					time_clip, 'sm'+probe+'_lon_bproj', t_0, t_end
				endif

			endif
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


			;;;;;;;;;;;;;;;;; Remove TII data of flag > 20 (PREL TII) ;;;;;;
			sufs_tii = ['_vi', '_efi', '_tempi', '_vih', '_viv']

			if strmatch_or(out_names[i], '*'+sufs_tii+'*') and tv_exist('sm'+probe+'_flagtii') then begin
				get_data, 'sm'+probe+'_flagtii', tflag, flags
				get_data, out_names[i], tout, out_data
				i_flags = where(flags ge value_flag_tii, n_flags)
				if n_flags gt 0 then begin
					out_data[i_flags,*] = !values.f_nan
					store_data, out_names[i], data = {x:tout, y:out_data}, limits = limits, dlimits = dlimits
				endif
			endif
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





			;;;;;;;;;;;;;;;;; Remove TII data of bad flag (EXPT TII) ;;;;;;
			sufs_tii = ['_viy', '_ex']

			if strmatch_or(out_names[i], '*'+sufs_tii+'*') and tv_exist('sm'+probe+'_qy') then begin
				get_data, 'sm'+probe+'_qy', tflag, flags
				get_data, out_names[i], tout, out_data
				i_flags = where(flags lt value_flag_tii, n_flags)
				if n_flags gt 0 then begin
					out_data[i_flags,*] = !values.f_nan
					store_data, out_names[i], data = {x:tout, y:out_data}, limits = limits, dlimits = dlimits
				endif
			endif
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


			;;;;;;; Subtract offset from TII flow and E field ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			if keyword_set(rtrange) and strmatch_or(out_names[i], ['*_vi*', '*_efi*', '*_e?']) then begin
				get_data, out_names[i], time, data, limits = limits, dlimits = dlimits

				;; compute the offset
				rtrange_d = time_double(rtrange)
				time_clip, out_names[i], rtrange_d[0], rtrange_d[1], newname = out_names[i]+'_quiet'
				get_data, out_names[i]+'_quiet', t_nouse, data_quiet
				offset = mean(data_quiet, dim = 1, /nan)
				if n_elements(size(data_quiet, /dim)) gt 1 then begin
					offset = transpose(offset)
					offset_arr = rebin(offset, n_elements(time), n_elements(offset))
				endif else begin
					offset_arr = replicate(offset, n_elements(time))
				endelse

				;; remove offset from data
				store_data, out_names[i]+'_dtrd', data = {x:time, y:data-offset_arr}, limits = limits, dlimits = dlimits
				if keyword_set(tclip) then begin
					del_data, out_names[i]+'_dtrd_tclip'
					time_clip, out_names[i]+'_dtrd', t_0, t_end
				endif
			endif
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of treatments ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


			; tclip the data
			if keyword_set(tclip) then begin
				del_data, out_names[i]+'_tclip'
				if n_elements(size(temp_data, /dim)) eq 3 then begin
					i_within = where((temp_time ge time_double(t_0)) and (temp_time le time_double(t_end)), n_within)
					if n_within gt 0 then begin
						store_data, out_names[i]+'_tclip', data = {x:temp_time[i_within], y:temp_data[i_within,*,*], v1:temp_v_angle, v2:temp_v[i_within,*]}, limits = limits, dlimits = dlimits 
					endif else print, 'Clip range not in range! No clip done.'
				endif else begin
					time_clip, out_names[i], t_0, t_end
				endelse
			endif

	   endif ;; if of loaded full data exist
	endfor ; for of i, outnames

	;;;;;;;;;;;;;;;;;; Quantities that depend on already existing (single operation) or multiple tplot variables ;;;;;;;;;;;;;;;;;;;;;;;

	;;;;;;;; Make the vih variable for the EXPT TII dataset ;;;;;;;;
	if tv_exist('sm'+probe+'_viy') and strcmp(datatype, 'EXPT_TII', /fold) then begin
		tnames_viy = tnames('sm'+probe+'_viy*')
		for i_name = 0, n_elements(tnames_viy)-1 do begin
			get_data, tnames_viy[i_name], t_viy, viy
			store_data, 'sm'+probe+'_vih'+strmid(tnames_viy[i_name], 7), data = {x:t_viy, y:[[viy*!values.f_nan], [viy]]}
		endfor
	endif
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	;;;;;;;;;;;;;;;; Compute Ex (along-track electric field) for PREL TII ;;;;;;;;;;;
	;;;; To be built

endfor ; for of p, probes

obj_destroy, download

end



time_range = time_double(['2013-12-25','2013-12-26'])
swarm_load, trange=time_range, probes='C', datatype='MAG'
end
