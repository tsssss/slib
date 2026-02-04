pro set_circ, fill=fill

    tmp = smkarthm(0,2*!dpi,20,'n')
    circ_xs = cos(tmp)
    circ_ys = sin(tmp)
    usersym, circ_xs, circ_ys, fill=fill
    
end