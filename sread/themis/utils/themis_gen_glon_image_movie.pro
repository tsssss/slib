;+
; Generate a movie for given time range and sites.
;-
pro themis_gen_glon_image_movie, glon_image_var, _extra=extra, filename=movie_file

    fig_dir = join_path([file_dirname(movie_file),'glon_image_figure'])
    fig_files = themis_gen_glon_image_figure(glon_image_var, _extra=extra, fig_dir=fig_dir)

    fig2movie, movie_file, fig_files=fig_files

end


; James Weygand's event.
time_range = time_double(['2018-02-23/08:30','2018-02-23/09:50'])
sites = ['fsim','fsmi','atha','tpas','gill']
glon_range = [-140,-80]
;glon_range = [-180,180]

glon_image_var = 'thg_asf_glon_image'
if check_if_update(glon_image_var) then themis_read_asf_glon_image, time_range, sites=sites
;movie_file = join_path([homedir(),'test','asf_glon_movie_'+time_string(time_range[0],tformat='YYYY_MMDD')+'_v02.mp4'])
;themis_gen_glon_image_movie, glon_image_var, filename=movie_file, $
;    time_step=15d, glat_range=[50,70], glon_range=glon_range, fig_xsize=6, zrange=[0,5e3]

mlt_image_var = 'thg_asf_mlt_image'
if check_if_update(mlt_image_var) then themis_read_asf_mlt_image, time_range, sites=sites
movie_file = join_path([homedir(),'test','asf_mlt_movie_'+time_string(time_range[0],tformat='YYYY_MMDD')+'_v02.mp4'])
themis_gen_mlt_image_movie, mlt_image_var, filename=movie_file, $
        time_step=15d, mlat_range=[50,90], fig_xsize=6, zrange=[0,5e3]
end