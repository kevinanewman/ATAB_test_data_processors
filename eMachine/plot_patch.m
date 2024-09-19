function hand = plot_patch(ax,  time_start, time_end, color)

hand = [];

if ~isempty( time_start) && ~isempty( time_end)
	patch_time = [time_start'; time_start'; time_end'; time_end'];
	patch_y = [ax.YLim,fliplr(ax.YLim)]' .* ones(1,size( patch_time,2),1);
	hand = patch(ax, patch_time, patch_y , -10*ones(4,size( patch_time,2)), color,'Linestyle','none');
end

end
