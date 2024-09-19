figs = findobj(0,'type','axes');
for i = 1:length(figs)
    xlim(figs(i),[gax1 gax2]);
end
