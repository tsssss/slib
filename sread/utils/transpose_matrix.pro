;+
; Transpose a matrix in [N,3,3] or [3,3].
;-
function transpose_matrix, m

    m_ndim = size(m,/n_dimension)
    m_dims = size(m,/dimensions)
    map_index = [0,3,6,1,4,7,2,5,8]

    case m_ndim of
        3: return, reform($
            (reform(m,[m_dims[0],m_dims[1]*m_dims[2]]))[*,map_index], m_dims[[0,2,1]])
        2: return, transpose(m)
        else: message, 'wrong dimension ...'
    endcase

end