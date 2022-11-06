;+
; Type: procedure.
; Purpose: Rotate 3-d vector by angle around axis.
; Parameters: vec, in/out, dblarr[n,3], required. 3-d vector.
;   ang, in, double, required. Rotation angle, default in radian.
;	axis, in, int, required. Axis of rotation. Can be 0,1,2.
; Keywords: degree, in, boolean, optional. Set when angle in degree.
; Notes: none.
; Dependence: none.
; History: 2013-04-16, Sheng Tian, create.
;-

pro srotate, vec, ang, axis, degree = degree

	compile_opt idl2

	t = (keyword_set(degree))? !dtor*ang: ang
	cost = cos(t)
	sint = sin(t)

	case axis of
		0: i = [1,2]
		1: i = [2,0]
		2: i = [0,1]
	endcase

	x0 = vec[*,i[0]]
	y0 = vec[*,i[1]]

	vec[*,i[0]] = x0*cost-y0*sint
	vec[*,i[1]] = x0*sint+y0*cost

end
