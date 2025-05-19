;+
; Solve the rotation matrix between two vectors.
;-

    rad = constant('rad')
    deg = constant('deg')

    vec0 = transpose([1d,2,3])
    rotation_angles = [0.23,-1,0.5]*rad
    

;---Test the equivalency of rotation and cross-product.
    vec_cross = vec0+vec_cross(vec0, rotation_angles)
    m_cross = [$
        [1,-rotation_angles[2],rotation_angles[1]], $
        [rotation_angles[2],1,-rotation_angles[0]], $
        [-rotation_angles[1],rotation_angles[0],1]]
    print, ''
    print, 'Cross:    ', reform(vec_cross)


    vec_rotation = vec0
    for ii=0,2 do srotate, vec2, rotation_angles[ii], ii
    m_rotation = [$
        [cos_theta*cos_phi
    print, ''
    print, 'Rotation: ', reform(vec_rotation)
    ;stop
    
    omega_hat = sunitvec(vec_cross(vec0, vec2))
    angle = (sang(vec0,vec2))[0]*0.5
    q = [cos(angle),sin(angle)*omega_hat]
    m_calc = qtom(q)
    ;print, m_calc
    print, ''
    print, 'Calc:     ', reform(rotate_vector(vec0,m_calc))
end
