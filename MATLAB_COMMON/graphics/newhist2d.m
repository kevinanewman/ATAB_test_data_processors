%function [ax] = newhist2d(binvar_x, bindef_x, binvar_y, bindef_y, rate, time)
%   creates contour plot of 2d integral histogram, used by ultramima
% returns: axis handle
function [ax, ch, hist2d_bindata] = newhist2d(binvar_x, bindef_x, binvar_y, bindef_y, rate, time, scale_min, scale_max, varargin)

do_plot = parse_varargs(varargin,'no_plot',true,'toggle');

quantity = rate.*derivative(time,1);
binmiddles_x = (bindef_x(1:length(bindef_x)-1)+bindef_x(2:length(bindef_x)))/2;
binmiddles_y = (bindef_y(1:length(bindef_y)-1)+bindef_y(2:length(bindef_y)))/2;

bins_xy = zeros(length(bindef_y)-1, length(bindef_x)-1);

last_index_x = 1;
last_index_y = 1;
for i = 1:length(time)
    target_val_x = binvar_x(i);
    target_val_y = binvar_y(i);

    if (target_val_x >= bindef_x(1)) && (target_val_x <= bindef_x(end)) && (target_val_y >= bindef_y(1)) && (target_val_y <= bindef_y(end)) && (quantity(i) ~= 0)
        if (bindef_x(last_index_x) <= target_val_x && (bindef_x(last_index_x+1) > target_val_x))
            index_x = last_index_x; % save some time here
        else            
            index_x = find((bindef_x <= target_val_x),1,'last');   % this takes awhile
            if (index_x == length(bindef_x)) 
                index_x = index_x - 1;
            end
        end        
        
        if (bindef_y(last_index_y) <= target_val_y && (bindef_y(last_index_y+1) > target_val_y))
            index_y = last_index_y; % save some time here
        else
            index_y = find((bindef_y <= target_val_y),1,'last');   % this takes awhile
            if (index_y == length(bindef_y)) 
                index_y = index_y - 1;
            end
        end
        
        bins_xy(index_y, index_x) = bins_xy(index_y, index_x)+quantity(i);
        last_index_x = index_x;
        last_index_y = index_y;
    end
end

if nargin > 6 && isnumeric(scale_min) % if scale_min and scale_max provided...
	
	bins_max = max(bins_xy(:));
	bins_min = min(bins_xy(:));
	
	bins_xy = scale_min +  (bins_xy - bins_min)./ (bins_max - bins_min) .* ( scale_max - scale_min ) ;
end

if do_plot
    % levels = linspace(min(bins_xy(:)), max(bins_xy(:)), 150);
    % % levels = levels(2:end-1); % not sure why this was here...
    % [c,ch] = contourf(binmiddles_x, binmiddles_y, bins_xy, levels,'LineStyle','none');

    ch = surf( binmiddles_x, binmiddles_y, zeros(size(bins_xy)), bins_xy ,'LineStyle','none');
    view(0,90); % set top view
    % shading interp
    
    xlim([bindef_x(1) bindef_x(end)]);
    ylim([bindef_y(1) bindef_y(end)]);
    grid on;
else
    ch.xdata = binmiddles_x;
    ch.ydata = binmiddles_y;
end

ax = gca;

hist2d_bindata = bins_xy;

end
