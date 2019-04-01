;+
; Test cotran and read_geopack_info.
;-
;

;---Settings.
    times = time_double(['2013-06-07/04:50','2013-06-07/05:00'])
    the_time = time_double('2013-06-07/04:55')
    probe = 'a'
    pre0 = 'rbsp'+probe+'_'
    format1 = '(F6.2)'  ; format for printing positions.
    url = 'http://data.phys.ucalgary.ca/sort_by_instrument/all_sky_camera/'+$
        'THEMIS/rt-mosaic/sat_footpoints/2013/06/sat_pos_20130607.sav'
    h0 = 100d  ; km, SSCWeb traces to this height.

    deg = 180d/!dpi
    rad = !dpi/180d

    model = 't89'
    par = 2.

    lprmsg, 'Test cotran.pro'
    lprmsg, 'Test time: '+time_string(the_time)
    lprmsg, 'Test probe: RBSP-'+strupcase(probe)


;---From SSCWeb.
    r0_gsm = [-4.39, 2.07, 2.86]
    r0_gse = [-4.39, 2.33, 2.65]
    r0_gei = [-3.28,-4.48, 0.95]
    r0_geo = [-0.56,-5.52, 0.95]
    r0_sm  = [-4.92, 2.07, 1.80]
    r0_mag = [ 4.86,-2.19, 1.80]
    r0_mlon = -24.29
    r0_mlat =  18.68
    r0_fmlon = -28.62
    r0_fmlat =  63.98

    lprmsg, 'From SSCWeb T89, the positions are: '
    lprmsg, 'GSM:  '+strjoin(string(r0_gsm,format=format1),', ')
    lprmsg, 'GSE:  '+strjoin(string(r0_gse,format=format1),', ')
    lprmsg, 'GEI:  '+strjoin(string(r0_gei,format=format1),', ')
    lprmsg, 'GEO:  '+strjoin(string(r0_geo,format=format1),', ')
    lprmsg, 'SM:   '+strjoin(string(r0_sm ,format=format1),', ')
    lprmsg, 'MAG:  '+strjoin(string(r0_mag,format=format1),', ')
    lprmsg, 'MLon: '+string(r0_mlon,format=format1)
    lprmsg, 'MLat: '+string(r0_mlat,format=format1)
    lprmsg, 'FMLon:'+string(r0_fmlon,format=format1)
    lprmsg, 'FMLat:'+string(r0_fmlat,format=format1)

;---From my program.
    rgsm_var = pre0+'r_gsm'
    if tnames(rgsm_var) eq '' then rbsp_read_orbit, times, probe=probe
    r1_gsm = get_var_data(rgsm_var, at=the_time)
    r1_gse = cotran(r1_gsm, the_time, 'gsm2gse')
    r1_gei = cotran(r1_gsm, the_time, 'gsm2gei')
    r1_geo = cotran(r1_gsm, the_time, 'gsm2geo')
    r1_sm  = cotran(r1_gsm, the_time, 'gsm2sm')
    r1_mag = cotran(r1_gsm, the_time, 'gsm2mag')
    r1_mlon = atan(r1_mag[1],r1_mag[0])*deg
    r1_mlat = asin(r1_mag[2]/snorm(r1_mag))*deg

    lprmsg, 'From my programs, the positions are: '
    lprmsg, 'GSM:  '+strjoin(string(r1_gsm, format=format1), ', ')
    lprmsg, 'GSE:  '+strjoin(string(r1_gse,format=format1),', ')
    lprmsg, 'GEI:  '+strjoin(string(r1_gei,format=format1),', ')
    lprmsg, 'GEO:  '+strjoin(string(r1_geo,format=format1),', ')
    lprmsg, 'SM:   '+strjoin(string(r1_sm ,format=format1),', ')
    lprmsg, 'MAG:  '+strjoin(string(r1_mag,format=format1),', ')
    lprmsg, 'MLon: '+string(r1_mlon,format=format1)
    lprmsg, 'MLat: '+string(r1_mlat,format=format1)


;---Test tracing.
    lprmsg, ''
    lprmsg, 'Test tracing to the ionosphere of the northern hemisphere'

;---From SPEDAS.
    fpt_var1 = 'f_gsm_spedas'
    ttrace2iono, rgsm_var, newname=fpt_var1, external_model=model, par=par
    f1_gsm = get_var_data(fpt_var1, at=the_time)
    lprmsg, 'From SPEDAS: '
    lprmsg, 'GSM:  '+strjoin(string(f1_gsm,format=format1))

    fpt_var2 = pre0+'fpt_gsm_'+model
    read_geopack_info, rgsm_var, model=model, h0=h0
    f2_gsm = get_var_data(fpt_var2, at=the_time)
    lprmsg, 'From my programs: '
    lprmsg, 'GSM:  '+strjoin(string(f2_gsm,format=format1))

    ; The mlon/mlat from my program.
    fmlon1 = get_var_data(pre0+'fmlon_'+model, at=the_time)
    fmlat1 = get_var_data(pre0+'fmlat_'+model, at=the_time)
    lprmsg, 'FMLon: '+string(fmlon1,format=format1)
    lprmsg, 'FMLat: '+string(fmlat1,format=format1)
    
    ; The mlon/mlat from THEMIS/ASI.
    lprmsg, ''
    lprmsg, 'From THEMIS/ASI, height = 200 km: '
    file = join_path([shomedir(),'Downloads',file_basename(url)])
    if file_test(file) eq 0 then download_file, file, url
    restore, file
    case probe of
        'a': sc_pos = sat_pos.rbspa
        'b': sc_pos = sat_pos.rbspb
    endcase
    the_epoch = convert_time(the_time, from='unix', to='epoch')
    fmlon2 = interpol(sc_pos.mlon, sc_pos.sat_epoch, the_epoch)
    fmlat2 = interpol(sc_pos.mlat, sc_pos.sat_epoch, the_epoch)
    lprmsg, 'FMLon: '+string(fmlon2,format=format1)
    lprmsg, 'FMLat: '+string(fmlat2,format=format1)
    
    
    fpt_var2 = pre0+'fpt_gsm_'+model
    read_geopack_info, rgsm_var, model=model, h0=sc_pos.height
    f2_gsm = get_var_data(fpt_var2, at=the_time)
    lprmsg, 'From my programs: '
    lprmsg, 'GSM:  '+strjoin(string(f2_gsm,format=format1))

    ; The mlon/mlat from my program.
    fmlon1 = get_var_data(pre0+'fmlon_'+model, at=the_time)
    fmlat1 = get_var_data(pre0+'fmlat_'+model, at=the_time)
    lprmsg, 'FMLon: '+string(fmlon1,format=format1)
    lprmsg, 'FMLat: '+string(fmlat1,format=format1)
    
    stop
    
end
