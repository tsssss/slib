;+
; Generate a movie for given time range and sites.
; mlt_image_var. The tplot var. Need to run themis_read_mlt_image first.
; filename=. A file name for the movie.
;-
pro themis_gen_mlt_image_movie, mlt_image_var, _extra=extra, filename=movie_file

    fig_dir = join_path([file_dirname(movie_file),'mlt_image_figure'])
    fig_files = themis_gen_mlt_image_figure(mlt_image_var, _extra=extra, fig_dir=fig_dir)

    fig2movie, movie_file, fig_files=fig_files

end


time_range = time_double(['2013-05-01/07:00','2013-05-01/08:00'])
sites = ['fsim','fsmi','atha']
sites = ['atha']
min_elev = 5
merge_method = 'merge_elev'
mlat_range = [60,90]
mission_probes = ['rbspb']

;mlt_image_var = themis_read_asf_mlt_image(time_range, sites=sites, min_elev=min_elev, $
;    merge_method=merge_method, mlat_range=mlat_range)
movie_file = join_path([homedir(),'test','test_asf_movie_2013_0501.mp4'])
themis_gen_mlt_image_movie, mlt_image_var, filename=movie_file, $
    mlt_range=[-1,1]*6, mlat_range=[50,90], fig_xsize=6, zrange=[0,1e4], $
    mission_probes=mission_probes, models=['t89'], igrf=0
stop


time_range = time_double(['2008-01-21/07:00','2008-01-21/08:00'])
sites = ['kian','mcgr','inuv','whit','fsim','fsmi','atha','tpas']
min_elev = 2.5
merge_method = 'merge_elev'
mlt_image_var = themis_calc_mlt_image(time_range, sites=sites, $
    smooth_window=2.5*60, min_elev=2.5, merge_method='merge_elev', mlat_range=[50d,90])

movie_file = join_path([homedir(),'test','asf_movie_2008_0121_v01.mp4'])
themis_gen_mlt_image_movie, mlt_image_var, filename=movie_file, $
    mlt_range=[-1,1]*6, mlat_range=[60,90], fig_xsize=6, zrange=[0,1e4]
stop


time_range = time_double(['2013-05-01/07:30','2013-05-01/07:45'])
sites = ['atha']
min_elev = 2.5
merge_method = 'merge_elev'
mlt_image_var = 'thg_asf_mlt_image'
themis_read_asf_mlt_image, time_range, sites=sites, min_elev=min_elev, $
    merge_method=merge_method, mlat_range=[60,90]

movie_file = join_path([homedir(),'test','asf_movie_2013_0501_v01.mp4'])
themis_gen_mlt_image_movie, mlt_image_var, filename=movie_file, $
    mlt_range=[-1,0]*2, mlat_range=[60,70], fig_xsize=3, zrange=[0,2e4]
stop


time_range = time_double(['2008-01-19/06:00','2008-01-19/09:00'])    ; fsim, gill
sites = ['fsim','gill','inuv']
min_elev = 2.5
merge_method = 'merge_elev'
mlt_image_var = 'thg_asf_mlt_image'
;if check_if_update(mlt_image_var, time_range) then
themis_read_asf_mlt_image, time_range, sites=sites, min_elev=min_elev, $
    merge_method=merge_method, mlat_range=[60,90]

movie_file = join_path([homedir(),'test','test_asf_movie_2008_0119.mp4'])
themis_gen_mlt_image_movie, mlt_image_var, filename=movie_file, $
    mlt_range=[-1,1]*6, mlat_range=[50,90], fig_xsize=6, zrange=[0,2.5e3]
stop

time_range = time_double(['2013-03-17/05:00','2013-03-17/10:00'])
sites = ['mcgr','fykn','gako','fsim', $
    'fsmi','tpas','gill','snkq','pina','kapu']
min_elev = 10
merge_method = 'max_elev'
mlt_image_var = 'thg_asf_mlt_image'
;if check_if_update(mlt_image_var, time_range) then 
themis_read_asf_mlt_image, time_range, sites=sites, min_elev=min_elev, merge_method=merge_method

movie_file = join_path([homedir(),'test','asf_movie_2013_0317_v02.mp4'])
themis_gen_mlt_image_movie, mlt_image_var, filename=movie_file, $
    time_step=600d, mlt_range=[-1,1]*6, mlat_range=[55,90], $
    fig_xsize=6, zrange=[0,2.5e3]
end