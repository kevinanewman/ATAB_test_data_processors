
function  [data_out] = process_high_load( data, data_format, source_file, file_type, engine, show_figs)

initial_enable = regexpcmp(file_type, '^HLI?$');
final_enable = regexpcmp(file_type, '^HLF?$');

data_out = table(0,0,'VariableNames',{'speed_rpm','torque_Nm'});
data_out = data_out([],:);

if ~istablevar( data, 'speed_rpm')
	warning('Data does not have data with working name speed_rpm, unable to perform high load processing')
	return;
end


if ~istablevar( data, 'torque_Nm')
	warning('Data does not have data with working name torque_Nm, unable to perform high load processing')
	return;
end

if ~istablevar(data, 'timestamp') && ~istablevar(data, 'elapsed_time_sec')
	warning('Data has neither a timestamp nor elapsed_time column, which is required for continuous files');
	return;
end

if ~istablevar(data, 'elapsed_time_sec')
	temp_timestampVec = datevec( data.timestamp );
	data.elapsed_time_sec = etime(temp_timestampVec, temp_timestampVec(1,:));
end

% Look at range of torques to possibly remove data
raw_torque_sort_Nm = sort(data.torque_Nm);
raw_torque_10pct_Nm =  raw_torque_sort_Nm(round(0.10* numel(raw_torque_sort_Nm)));
raw_torque_90pct_Nm =  raw_torque_sort_Nm(round(0.90* numel(raw_torque_sort_Nm)));

% Remove invalid_test
if  raw_torque_90pct_Nm - raw_torque_10pct_Nm < engine.max_torque_Nm * 0.1
	warning('Data does not have sufficient torque transient, skipping high load processing');
	return;
end

% End limit for tests that include ramp back down
torque_end_limit_Nm = 0.30* raw_torque_10pct_Nm + 0.70*raw_torque_90pct_Nm;
torque_end_limit_idx = find( data.torque_Nm > torque_end_limit_Nm, 1, 'last');
keep = data.elapsed_time_sec < data.elapsed_time_sec(torque_end_limit_idx) - 0.5;
data = data(keep,:);


% Look at range of torques to possibly remove data
raw_torque_sort_Nm = sort(data.torque_Nm);
raw_torque_10pct_Nm =  raw_torque_sort_Nm(round(0.10* numel(raw_torque_sort_Nm)));
raw_torque_90pct_Nm =  raw_torque_sort_Nm(round(0.90* numel(raw_torque_sort_Nm)));

% Remove invalid_test
if  raw_torque_90pct_Nm - raw_torque_10pct_Nm < engine.max_torque_Nm * 0.1
	warning('Data does not have sufficient torque transient, skipping high load processing');
	return;
end



%TODO: Cleanup

% Transient Data - Select Initial & Final Windows
data_stable = check_transient_stability( data, data_format );

% Set window for filtering data - moving avg assume constant data rate
filter_pts =     ceil([0.20, 0.10] .* length(data.elapsed_time_sec) ./data.elapsed_time_sec(end));    %0.20 seconds back and 0.10 seconds ahead


% Filter pertinent signals for window selection
filt_torque_Nm = movmean( data.torque_Nm, filter_pts);
filt_exhaust_lambda = movmean( data.exhaust_lambda,  filter_pts);

% Surrogate fuel flow meter stability if factor not provided
if istablevar( data_stable, 'meter_fuel_flow_gps')
	fuel_flow_stable = data_stable.meter_fuel_flow_gps;
else
	fuel_flow_stable = stable_check( data.meter_fuel_flow_gps, data.elapsed_time_sec, mean(data.meter_fuel_flow_gps)* 0.025 );
end

% Time Windows for Initial & Final
% torque_sort_Nm = sort(data.torque_Nm);
torque_75pct_Nm =  nrmtile(data.torque_Nm, 0.75); %torque_sort_Nm(round(0.75* numel(torque_sort_Nm)));
high_load_t_0_idx = find(filt_torque_Nm > (torque_75pct_Nm - engine.max_torque_Nm * 0.05),1,'first');
high_load_t_0 = data.elapsed_time_sec(high_load_t_0_idx);

data.relative_time_sec = data.elapsed_time_sec - high_load_t_0;

high_load_pts = data.relative_time_sec >= 0;
high_load_torque_Nm = mean(data.torque_Nm( high_load_pts));
high_load_speed_rpm = mean(data.speed_rpm( high_load_pts));

if nrmtile(data.exhaust_lambda( high_load_pts), 0.25) < 0.95
	
	full_enrich_lambda = nrmtile(data.exhaust_lambda( high_load_pts), 0.05);
	rough_enrich_pts = filt_exhaust_lambda < (1+full_enrich_lambda)/2;
	rough_stoich_pts = ~rough_enrich_pts;
	
	high_load_stoich_lambda = min([1.0,nrmtile(min(data.exhaust_lambda(rough_stoich_pts),1.01), 0.50)]);
	high_load_rich_lambda = nrmtile(data.exhaust_lambda( high_load_pts & rough_enrich_pts ), 0.30);
	
	enrich_complete_lambda = 0.10*high_load_stoich_lambda + 0.90*high_load_rich_lambda;
	enrich_start_lambda = 0.95*high_load_stoich_lambda + 0.05*high_load_rich_lambda ;
	
	high_load_t_enrich_complete = data.relative_time_sec(find(  filt_exhaust_lambda < enrich_complete_lambda  ,1,'first'));
	high_load_t_enrich_start = data.relative_time_sec(find(filt_exhaust_lambda > enrich_start_lambda & data.relative_time_sec < high_load_t_enrich_complete , 1,'last'));
	
else
	
	% Not sufficient enrichment
	high_load_t_enrich_start = nan;
	high_load_t_enrich_complete = nan;
		
end


% Rough time limits based on enrichment
initial_min_start_time = 0;
initial_max_end_time =  2;

final_min_start_time = max( high_load_t_enrich_complete, 2.5 );


% Initial Window ----------------------------------------------
initial_window_flag = data.relative_time_sec > initial_min_start_time & data.relative_time_sec < initial_max_end_time;
offset = -0.02;
window_score = 0;
while all(window_score < 0.5)
	offset = offset+0.01;
	initial_torque_limit_Nm = high_load_torque_Nm - engine.max_torque_Nm * offset;
	initial_stable_flag = initial_window_flag & filt_torque_Nm > initial_torque_limit_Nm ;%&  data.torque_Nm > initial_torque_limit;
	[initial_start_time, initial_end_time] = select_data_windows( data.relative_time_sec, initial_stable_flag, 0.5, 'all');
	window_score = (initial_end_time - initial_start_time) - (initial_start_time - initial_min_start_time)* 0.3;
end

[window_score, idx] = max(window_score);
initial_start_time = initial_start_time(idx);
initial_end_time =  initial_end_time(idx);


if ~isempty(initial_start_time)
	
	pts = data.relative_time_sec >= initial_start_time & data.relative_time_sec <= initial_end_time;
	window_data = data(pts,:);
	
	avg_initial = calc_continuous_stats(window_data , data_format );
	
	% Remove unstable variables
	avg_initial_stable = check_portion_stability( data_stable, pts, 0.9 );
	for v = 1:width( avg_initial_stable)
		var = avg_initial_stable.Properties.VariableNames{v};
		if ~avg_initial_stable.(var)
			avg_initial.(var) = nan;
		end
	end
	

	
	if initial_enable
		% Save window times, point type and file
		avg_initial.start_time = initial_start_time;
		avg_initial.end_time = initial_end_time;
		avg_initial.record_duration = initial_end_time - initial_start_time;
		avg_initial.data_type = {'HL-initial'};
		avg_initial.source_file = {source_file};
		
		data_out = outerjoin( data_out, avg_initial, 'MergeKeys',true);
	end
	
end


% Final Window ------------------------------------------------------
final_start_time = data.relative_time_sec(find( data.relative_time_sec > final_min_start_time  & fuel_flow_stable, 1, 'first'));
final_end_time = data.relative_time_sec(end);

if ~isempty( final_start_time )
	pts = data.relative_time_sec >= final_start_time & data.relative_time_sec <= final_end_time;
	avg_final = calc_continuous_stats( data(pts,:), data_format );
	
	% Remove unstable variables
	avg_final_stable = check_portion_stability( data_stable, pts, 0.9 );
	for v = 1:width( avg_final_stable)
		var = avg_final_stable.Properties.VariableNames{v};
		if ~avg_final_stable.(var) %< 0.9
			avg_final.(var) = nan;
		end
	end
	

	
	
	if final_enable
		% Save window times, point type and file
		avg_final.start_time = final_start_time;
		avg_final.end_time = final_end_time;
		avg_final.record_duration = final_end_time - final_start_time;
		avg_final.data_type = {'HL-final'};
		avg_final.source_file = {source_file};
	
		data_out = outerjoin( data_out, avg_final, 'MergeKeys',true);
	end
	
end


fig = figure('Visible',show_figs);

% Title
[~,filename, fileext] = fileparts(source_file);
annotation(fig,'textbox', [0.05,0.92,0.9,0.05],'String',sprintf( '%s%s  - %.0f RPM', filename, fileext, high_load_speed_rpm ), 'interpreter','none','FontSize',15,'LineStyle','none','HorizontalAlignment','center');

% Make the plots
[ax_hand, line_hand] = plot_continuous_data( data, data_stable, data_format );

% Add patches and timing 
for i = 1:numel(ax_hand)
	
	if	~strcmpi( ax_hand(i).YAxisLocation, 'Left')
		yyaxis(ax_hand(i),'left');
	end
	
	plot_times( ax_hand(i), high_load_t_enrich_start, high_load_t_enrich_complete);
	
	% Draw patches
if initial_enable && ~isempty( initial_start_time)
		plot_patch(ax_hand(i), initial_start_time, initial_end_time, [0.67, 0.70, 0.90]);
	end
	
if final_enable && ~isempty( final_start_time)
		plot_patch(ax_hand(i), final_start_time, final_end_time, [0.65, 0.90, 0.65]);
	end
	
	set(ax_hand(i),'SortMethod','depth');
	
end

% Fake axes for region marking
leg_ax = axes('Position',[1.1,0.90, 0.6 ,0.001],'visible','off');
leg_final_patch = plot_patch(leg_ax, 5, 6, [0.65, 0.90, 0.65] );
leg_initial_patch = plot_patch(leg_ax, 1, 2, [0.67, 0.70, 0.90]);
leg_hand = legend([ leg_initial_patch, leg_final_patch ], {'High Load Initial','High Load Final'},'orientation','horizontal','box','off','Position', [0.13, 0.89, 0.775, 0.04]);

end




function [stable_start_time, stable_end_time] = select_data_windows( time, good_pts,  min_window_size, select )

if nargin < 4
	select = 'all';
end

% Ensure first and last transisitions are unstable-> stable and stable-> unstable
good_pts(1) = false;
good_pts(end) = false;

% Convert Stable flag to time
stable_start_time = time(find(diff(good_pts) > 0));
stable_end_time = time(find(diff(good_pts) < 0));
short_window = (stable_end_time - stable_start_time) < min_window_size;
stable_start_time(short_window) = [];
stable_end_time(short_window) = [];

if isempty( stable_start_time )
	% 	stable_flag = false(size(stable_flag));
	return;
elseif strcmpi(select,'first')
	stable_start_time = stable_start_time(1);
	stable_end_time = stable_end_time(1);
elseif strcmpi(select,'last')
	stable_start_time = stable_start_time(end);
	stable_end_time = stable_end_time(end);
end


end



function data_stable = check_portion_stability( data_stable_flags, pts, thresh )

data_stable = [];
numeric_data = [data_stable_flags(:,vartype('numeric')),data_stable_flags(:,vartype('logical'))]  ;

test_fun = @(x) mean(double(x)) > thresh;
data_stable = varfun(test_fun, numeric_data(pts,:) );
data_stable.Properties.VariableNames = numeric_data.Properties.VariableNames;

end



function hand = plot_times( ax, t_enrich_start, t_enrich_complete)

hand = [];

ylims = ax.YLim;
ymin = ylims(1);
ymax = ylims(end);

line(ax, [0,0],ylims,'color','k');
text(ax, 0, ymin,'t_0 ','HorizontalAlignment','Right','VerticalAlignment','Bottom');

line(ax, [t_enrich_start, t_enrich_start],ylims,'color','m');
text(ax, t_enrich_start, ymax,'t_{start} ','HorizontalAlignment','Right','VerticalAlignment','Top');
line(ax, [t_enrich_complete, t_enrich_complete],ylims,'color','g');
text(ax, t_enrich_complete, ymax,' t_{complete}','HorizontalAlignment','Left','VerticalAlignment','Top');

end



