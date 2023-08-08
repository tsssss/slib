
function test_dmsp_madrigal_api, input_time_range, probe=probe

    errmsg = ''
    retval = !null

    remote_root = 'http://cedar.openmadrigal.org'
    local_root = join_path([default_local_root(),'dmsp_madrigal'])
    instrument_code = 8100  ; for DMSP, found by the block below.
    
    ; Get instrument code for a given instrument.
    if n_elements(instrument_code) eq 0 then begin
        dmsp_name = 'Defense Meteorological Satellite Program'
        instrument_infos = madgetallinstruments(remote_root)
        foreach instrument_info, instrument_infos do begin
            if instrument_info.name eq dmsp_name then break
        endforeach
        if instrument_info.name ne dmsp_name then begin
            errmsg = 'Instrument or probe not found ...'
            return, retval
        endif

        instrument_code = instrument_info.code
        print, 'DMSP instrument code: '+string(instrument_code)
    endif

    
    ; Time range.
    time_range = time_double(input_time_range)
    time_info = strsplit(time_string(time_range, tformat='YYYY_MM_DD'),'_',extract=1)
    start_time_info = float(time_info[0])
    end_time_info = float(time_info[1])
    iyear = start_time_info[0]
    imonth = start_time_info[1]
    iday = start_time_info[2]
    oyear = end_time_info[0]
    omonth = end_time_info[1]
    oday = end_time_info[2]
    
    expid = fix('1011'+strmid(probe,0,1,reverse=1))
    tr_jd = convert_time(time_range, from='unix', to='jd')
    local_path = join_path([local_root,'dmsp'+probe,time_string(time_range[0],tformat='YYYY')])
    if file_test(local_path) eq 0 then file_mkdir, local_path
    madglobaldownload, remote_root, local_path, $
        'Sheng+Tian', 'ts0110@atmost.ucla.edu', 'UCLA', $
        tr_jd[0],tr_jd[1], instrument_code, expid, 'hdf5'
    stop
    ; Get experiments.
    is_local_experiment = 0
    exp_infos = madgetexperiments(remote_root, instrument_code, $
        iyear,imonth,iday,0,0,0, $
        oyear,omonth,oday,0,0,0, is_local_experiment )
    ; expid: 100136868
;    10115  F15 1 sec values (ion drift / magnetometer / electron density)/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_15s1.001.hdf5
;    10116  F16 1 sec values (ion drift / magnetometer / electron density)/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_16s1.001.hdf5
;    10117  F17 1 sec values (ion drift / magnetometer / electron density)/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_17s1.001.hdf5
;    10118  F18 1 sec values (ion drift / magnetometer / electron density)/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_18s1.001.hdf5
;    10119  F19 1 sec values (ion drift / magnetometer / electron density)/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_19s1.001.hdf5
;    10145  F15 4 sec values (plasma temp / O+ fract / vehicle pot)/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_15s4.001.hdf5
;    10146  F16 4 sec values (plasma temp / O+ fract / vehicle pot)/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_16s4.001.hdf5
;    10147  F17 4 sec values (plasma temp / O+ fract / vehicle pot)/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_17s4.001.hdf5
;    10148  F18 4 sec values (plasma temp / O+ fract / vehicle pot)/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_18s4.001.hdf5
;    10149  F19 4 sec values (plasma temp / O+ fract / vehicle pot)/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_19s4.001.hdf5
;    10216  F16 flux/energy values/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_16e.001.hdf5
;    10217  F17 flux/energy values/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_17e.001.hdf5
;    10218  F18 flux/energy values/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_18e.001.hdf5
;    10219  F19 flux/energy values/opt/cedar3/experiments3/2015/dms/16mar15/dms_20150316_19e.001.hdf5
;    10300  Hemispherical power values/opt/cedar3/experiments3/2015/dms/16mar15/hp20150316_000.hdf5
;    10245  F15 UT SSIES-2 DMSP with quality flags/opt/cedar3/experiments3/2015/dms/16mar15/dms_ut_20150316_15.001.hdf5
    foreach exp_info, exp_infos do begin
        exp_id = exp_info.strid
        exp_files = madgetexperimentfiles(remote_root, exp_id, 1)
        foreach exp_file, exp_files do begin
            print, string(exp_file.kindat,format='(I10)')+'  ', exp_file.kindatdesc, exp_file.name
        endforeach
        stop
    endforeach

end


tr = ['2015-03-17','2015-03-18']
probe = 'f18'
print, test_dmsp_madrigal_api(tr, probe=probe)
end