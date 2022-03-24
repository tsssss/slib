;+
; Generate a movie for given time range and sites.
;-
pro themis_gen_mlon_image_movie, mlon_image_var, _extra=extra, filename=movie_file

    fig_dir = join_path([file_dirname(movie_file),'mlon_image_figure'])
    fig_files = themis_gen_mlon_image_figure(mlon_image_var, _extra=extra, fig_dir=fig_dir)

    fig2movie, movie_file, fig_files=fig_files

end


time_range = time_double(['2013-03-17/05:00','2013-03-17/10:00'])
sites = ['mcgr','fykn','gako','fsim', $
    'fsmi','tpas','gill','snkq','pina','kapu']
;sites = ['mcgr','fykn','gako','fsim']
min_elev = 10d
merge_method = 'max_elev'
mlon_image_var = 'thg_asf_mlon_image'
if check_if_update(mlon_image_var) then $
    themis_read_asf_mlon_image, time_range, sites=sites, min_elev=min_elev, merge_method=merge_method

movie_file = join_path([homedir(),'test','test_asf_mlon_movie.mp4'])
themis_gen_mlon_image_movie, mlon_image_var, filename=movie_file, $
    time_step=600d, mlat_range=[55,90], mlon_range=[-120,20], fig_xsize=6, zrange=[0,2e3]
end