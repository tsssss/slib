;+
; Return n colors.
;-
function get_color, ncolor, color_table=color_table, bottom_color=bottom_color, top_color=top_color

        default_colors = ['red','green','blue','purple','cyan','orange','black',$
            'deep_pink','olive','dodger_blue','indigo','dark_cyan','firebrick','grey']
        ndefault_color = n_elements(default_colors)
        if ncolor le ndefault_color then return, sgcolor(default_colors[0:ncolor-1])

        named_colors = (dictionary(!color)).keys()
        nnamed_color = n_elements(named_colors)
        if ncolor gt nnamed_color then begin
            if n_elements(bottom_color) eq 0 then bottom_color = 50
            if n_elements(top_color) eq 0 then top_color = 200
            if n_elements(color_table) eq 0 then color_table = 52

            colors = smkarthm(bottom_color,top_color,ncolor,'n')
            for ii=0, ncolor-1 do colors[ii] = sgcolor(colors[ii], ct=color_table)
            return, colors
        endif

        colors = list(default_colors, extract=1)
        foreach color, strlowcase(named_colors) do begin
            if colors.where(color) eq !null then colors.add, color
            if colors.length eq ncolor then break
        endforeach
        return, sgcolor(colors.toarray())
        
end


ncc = 14
ncc = 20
ccs = get_color(ncc)
plot, [0,1], [-1,ncc], $
    xstyle=1, ystyle=1, nodata=1
foreach cc, ccs, ii do begin
    plots, [0,1], ii+[0,0], color=cc, thick=4
endforeach


end