function normalize, data, array = array, vector = vector
;;; normalize the input 3-dim data
;;; if the data is 3x3, default is a vector |x|y|z|
;;; array: to indicate that this is in fact an array. But this will not override dim
;;; return value: normalized data (direction only)

dim1 = n_elements(data[*,0])
dim2 = n_elements(data[0,*])


case 1 of
(dim1 eq 3 and dim2 ne 3) or (dim1 eq 3 and ~keyword_set(array)): begin
	length = sqrt(total(data^2, 1))
	if dim2 gt 1 then length = transpose(length)
	data_nor = data/[length, length, length]
	end
(dim2 eq 3 and dim1 ne 3) or (dim2 eq 3 and keyword_set(array)): begin
	length = transpose(sqrt(total(data^2, 2)))
	data_nor = data/[[length], [length], [length]]
	end
else: message, 'Dimension not correct!'
endcase

return, data_nor

end
