FUNCTION rotation_matrix, $
	instrument_roll, $
	instrument_elevation, $
	instrument_azimuth, $
	spacecraft_spin, $
	attitude, $
	spin_phase

;Check arguments
IF N_Elements(instrument_roll) EQ 0 THEN Return, -1
IF N_Elements(instrument_elevation) EQ 0 THEN Return, -1
IF N_Elements(instrument_azimuth) EQ 0 THEN Return, -1
IF N_Elements(spacecraft_spin) EQ 0 THEN Return, -1
IF N_Elements(attitude) EQ 0 THEN Return, -1
IF N_Elements(spin_phase) EQ 0 THEN Return, -1

eps = 1D-3
IF (Magnitude(spacecraft_spin[0], spacecraft_spin[1], spacecraft_spin[2]) - 1D) GT eps THEN $
	spacecraft_spin = [0D, 0D, 1D]
IF (Magnitude(attitude[0], attitude[1], attitude[2]) - 1D) GT eps THEN attitude = [0D, -1D, 0D]
IF (attitude[0] EQ 0D) && (attitude[1] EQ 0D) && (Abs(attitude[2]) EQ 1D) THEN $
	Message, "No solution for attitude = [0, 0, 1] or [0, 0, -1]!"

;transform angles to radians
degree_to_radian = !DPI / 180D
omega = instrument_roll * degree_to_radian
theta = instrument_elevation * degree_to_radian
phi = instrument_azimuth * degree_to_radian
psi = spin_phase * degree_to_radian

;T1 is the transformation from the instrument space with the axis
;	x along x-axis of image
; 	y along y-axis of image
;	z pointing into the instrument
;into the spacecraft system with
;	z' away from the instrument deck along central metal axis
;	x' perpendicular to one side of deck plate
;	y' completing right handed system

T1_a = [ [ Cos(omega),-Sin(omega), 0D        ], $
	 	 [ Sin(omega), Cos(omega), 0D        ], $
	 	 [ 0D        , 0D        , 1D        ] ]

T1_b = [ [ 1D        , 0D        , 0D        ], $
	     [ 0D        ,-Sin(theta),-Cos(theta)], $
	 	 [ 0D        , Cos(theta),-Sin(theta)] ]

T1_c = [ [ Sin(phi)  , Cos(phi)  , 0D        ], $
	 	 [-Cos(phi)  , Sin(phi)  , 0D        ], $
	 	 [ 0D        , 0D        , 1D        ] ]

T1 = T1_c ## (T1_b ## T1_a)

;T2 is the transformation from the spacecraft system into the true
;spinning system with the axis
;	z'' true spin axis
;	x'' defined this way that x' lies in x'' - z'' plane
;	y'' completing system
;
;input here are direction cosines of true spin axis in spacecraft
;system, they should not change with time once the spacecraft is
;fully deployed
;	spacecraft_spin[1] = henry's a
;	spacecraft_spin[2] = henry's b
;	spacecraft_spin[3] = henry's c

sin_beta = spacecraft_spin[0]
cos_beta = Sqrt(1D - spacecraft_spin[0] * spacecraft_spin[0])
sin_alpha = spacecraft_spin[1] / cos_beta
cos_alpha = spacecraft_spin[2] / cos_beta

T2_a = [ [ 1D      , 0D       , 0D        ], $
         [ 0D      , cos_alpha,-sin_alpha ], $
         [ 0D      , sin_alpha, cos_alpha ] ]
T2_b = [ [ cos_beta, 0D       ,-sin_beta  ], $
         [ 0D      , 1D       , 0D        ], $
         [ sin_beta, 0D       , cos_beta  ] ]

T2 = T2_b ## T2_a

;T3 is the transformation from the true spinning system into the
;inertial GCI system
;	attitude[0] = henry's d
;	attitude[1] = henry's e
;	attitude[2] = henry's f

cos_eta = attitude[2] / cos_beta
sin_eta = Sqrt(1D - spacecraft_spin[0]^2 - attitude[2]^2) / cos_beta
cos_delta = (spacecraft_spin[0] * attitude[0] + $
	attitude[1] * Sqrt(1D - spacecraft_spin[0]^2 - attitude[2]^2)) / (1D - attitude[2]^2)
sin_delta = (spacecraft_spin[0] * attitude[1] - $
	attitude[0] * Sqrt(1D - spacecraft_spin[0]^2 - attitude[2]^2)) / (1D - attitude[2]^2)

T3_a = [ [ Cos(psi),-Sin(psi), 0D      ], $
	  	 [ Sin(psi), Cos(psi), 0D      ], $
	 	 [ 0D       , 0D       , 1D      ] ]
T3_b = [ [ cos_beta , 0D       , sin_beta], $
	 	 [ 0D       , 1D       , 0D      ], $
	 	 [-sin_beta , 0D       , cos_beta] ]
T3_c = [ [ 1D       , 0D       , 0D      ], $
	 	 [ 0D       , cos_eta  , sin_eta ], $
	     [ 0D       ,-sin_eta  , cos_eta ] ]
T3_d = [ [ cos_delta,-sin_delta, 0D      ], $
	 	 [ sin_delta, cos_delta, 0D      ], $
	 	 [ 0D       , 0D       , 1D      ] ]
T3 = T3_d ## (T3_c ## (T3_b ## T3_a))

transformation_matrix = T3 ## (T2 ## T1)

Return, transformation_matrix

END