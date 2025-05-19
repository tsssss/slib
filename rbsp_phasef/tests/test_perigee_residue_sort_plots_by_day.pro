;+
; Sort plots by day.
;-


    plot_dir = join_path([googledir(),'works','rbsp_phase_f','plot'])
    versions = 'test_perigee_emgse'+['','_change_vel','_change_adhoc']
    map_names = ['raw','vel_pos','fit_vxb']

    files = file_search(join_path([plot_dir,versions[0],'*.pdf']))
    out_dir = join_path([plot_dir,'plots_by_day'])
    if file_test(out_dir) eq 0 then file_mkdir, out_dir
    foreach file, files do begin
        base_name = fgetbase(file)
        foreach version, versions, ii do begin
            in_file = join_path([plot_dir,versions[ii],base_name])
            map_base_name = strmid(base_name,0,strpos(base_name,'.pdf'))+'_'+map_names[ii]+'.pdf'
            out_file = join_path([out_dir,map_base_name])
            file_copy, in_file, out_file
        endforeach
    endforeach
end