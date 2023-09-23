function efield_calc_dc_offset, e_comp, width

    offset1 = smooth(e_comp, width, nan=1, edge_zero=1)
    return, smooth(offset1, width, nan=1, edge_zero=1)

end