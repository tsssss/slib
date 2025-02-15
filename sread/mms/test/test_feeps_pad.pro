;+
; Compare consistency between mms_load_feeps and my version.
;-


tr = ['2015-09-01','2015-09-02']
probe = '4'

prefix = 'mms'+probe+'_'
prefix2 = prefix+'epd_feeps_srvy_l2_electron_'
sensor_ids = ['3','4','5','11','12']

load_data = 1

if load_data then begin
;---The original process.
    var = mms_read_kev_electron_raw(tr, probe=probe)
    out_var = var+'_target'
    var1 = rename_var(var, output=out_var)
    ; Rename vars.
    foreach side, ['top','bottom'] do begin
        foreach id, sensor_ids do begin
            vars = prefix2+side+'_intensity_sensorid_'+id+'_'+['clean','clean_sun_removed','500keV_int']
            foreach var, vars do begin
                if tnames(var) ne var then stop
                out_var = var+'_target'
                print, rename_var(var, output=out_var)
            endforeach
        endforeach
    endforeach

;---My process. Need to run after the original.
    test_file = join_path([homedir(),'test_feeps.cdf'])
    file = mms_ld_feeps_pad_ele_gen_file(tr, probe=probe, filename=test_file)
    var2 = mms_read_kev_electron(tr, probe=probe, spec=1)
endif

suffixs = ['','_target']
foreach side, ['top','bottom'] do begin
    foreach id, sensor_ids do begin
        vars = list()
        vars.add, extract=1, prefix2+side+'_intensity_sensorid_'+id+'_clean'+suffixs
        vars.add, extract=1, prefix2+side+'_intensity_sensorid_'+id+'_clean_sun_removed'+suffixs
        vars.add, extract=1, prefix2+side+'_intensity_sensorid_'+id+'_500keV_int'+suffixs
        vars = vars.toarray()

        tplot, vars
        stop
    endforeach
endforeach

end