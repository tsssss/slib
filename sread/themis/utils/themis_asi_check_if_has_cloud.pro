;+
; Check if ASF in a given time range has cloud.
;-

function themis_asi_check_if_has_cloud, input_time_range, site=site, errmsg=errmsg

    time_range = time_double(input_time_range)
    asf_var = themis_read_asf(time_range, site=site, errmsg=errmsg)
    get_data, asf_var, times, asf_images
    stop
    image_size = size(reform(asf_images[0,*,*]))
    plot_file = 0
    zrange = [4000d,10000]
    tpos = [0,0,1,1]
    ct = 49
    color_top = 254
    

    sgopen, plot_file, size=image_size
    foreach time, times, time_id do begin
        sgtv, bytscl(reform(asf_images[time_id,*,*]), max=zrange[1], min=zrange[0], top=color_top), position=tpos, ct=ct
    endforeach

    stop

end


; examples of cloud data.
site = 'whit'
time_range = ['2015-03-11/09:00','2015-03-11/13:00']
tmp = themis_asi_check_if_has_cloud(time_range, site=site)
end