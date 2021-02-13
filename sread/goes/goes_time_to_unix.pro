
function goes_time_to_unix, times

    time0 = time_double('2000-01-01/12:00')
    return, times+time0
    
end
