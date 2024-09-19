function levels = best_contour(z_grid,num_levels, range_limits, force_linear, min_step)
%% BEST_CONTOUR selects given number of contour lines
% A simple algorithm which sorts the data, and linearly steps through
% the data points to select 



z_pts = z_grid;

if nargin >=3
	z_pts = z_pts( ~isnan(z_pts) & ~isinf(z_pts) & z_pts>=range_limits(1) & z_pts<=range_limits(2) );
else
	z_pts = z_pts( ~isnan(z_pts) & ~isinf(z_pts) );
end
% 
z_pts = sort(z_pts);



min_contour = z_pts(1);% + (z_pts(end) - z_pts(1)) * 0.001;
max_contour = z_pts(end);% -  + (z_pts(end) - z_pts(1)) * 0.001;

% z_pts_filt = movmean( z_pts, ceil(length(z_pts) / 10) );
level_idxs = round(linspace(1,length(z_pts),num_levels));
levels_raw = z_pts(level_idxs);
levels_unique = unique(levels_raw);

delta = diff(levels_raw);

if  force_linear || ( std( delta) < mean(delta) * 1.5 ) 
	
	% Less steps is data has plateaus
	num_steps = numel(levels_unique);
	
	step = (max_contour - min_contour)./ num_steps;		
	step = compute_step( step );
	step = max(step, min_step);
		
	start = step .* ceil(min_contour ./ step);
	levels = [start:step:max_contour]';
	
elseif length(levels_unique) <= 1
	
	levels = levels_unique;
else
	
	levels =levels_unique;
	delta = diff(levels);
	delta = min([delta(1); delta(:)] , [delta(:); delta(end)] );

	rounding = max( compute_step(movmean(delta,4)), min_step );
	
	levels_r = rounding .* round(levels ./ rounding);
	levels_c = rounding .* ceil(levels ./ rounding);
	levels_f = rounding .* floor(levels ./ rounding);
	
	levels = unique([levels_c(1); levels_r(2:end-1); levels_f(end)]);
	
end



end

function step = compute_step( step )

	log_step = log10( step);
	log_floor = floor(log_step);
	log_decimal = log_step - log_floor;
	
	steps = [1,2,5,10];
	
	step = 10.^log_floor .* interp1(steps, steps, 10.^log_decimal, 'nearest');
		
end	
	
