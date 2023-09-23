function themis_get_m_smc2spg

    ; Table 1 on P513 in the Themis mission book.
    ; Need transpose b/c idl's array indexing.
    return, transpose([$
        [0.9777,-0.2100, 0.0000], $
        [0.2100, 0.9777, 0.0000], $
        [0.0000, 0.0000, 1.0000]])

end