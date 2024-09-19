function [sel_data, out_data] = process_min_torque( raw_data, data_format, file, engine, show_figs )


if ~istablevar(raw_data, 'elapsed_time_sec') && istablevar(raw_data,'timestamp')
	temp_timestampVec = datevec( raw_data.timestamp );
	raw_data.elapsed_time_sec = etime(temp_timestampVec, temp_timestampVec(1,:));
end

sel_pts = raw_data.torque_Nm <= 0;
sel_pts = sel_pts & raw_data.speed_rpm > engine.idle_speed_rpm;

if istablevar(raw_data,'accel_pedal_pos')
	% Remove points with accelerator pedal signal
	sel_pts = sel_pts & raw_data.accel_pedal_pos < nrmtile(raw_data.accel_pedal_pos, 0.1) + 2;
end

if istablevar(raw_data,'throttle_pos')
	% Remove points where throttle is substantially open
	sel_pts = sel_pts & raw_data.throttle_pos < nrmtile(raw_data.throttle_pos, 0.1) + 2;
end



% if istablevar(data,'meter_fuel_flow_gps')
% 	% Remove points with substantial fuel flow
% 	sel_pts = sel_pts & data.meter_fuel_flow_gps < 1.1 * max(0, nrmtile(data.meter_fuel_flow_gps, 0.5));
% end


trq_filt = movmean( raw_data.torque_Nm, max(7, ceil(height(raw_data)*0.025)) );
trq_rate = 1000 * [0;diff(trq_filt)./diff(raw_data.elapsed_time_sec)];

sel_pts = sel_pts & abs( raw_data.torque_Nm - trq_filt ) <  0.01 * engine.max_torque_Nm;
sel_pts = sel_pts & abs( trq_rate ) < 10 * engine.max_torque_Nm;


if ~any( sel_pts )
	sel_data = [];
	out_data = [];
	return;
end
	



% Select Points
sel_data = raw_data(sel_pts,:);
% sel_core_data = raw_data(sel_pts,{'speed_rpm','torque_Nm','meter_fuel_flow_gps','injector_fuel_flow_gps'});

% Filter provided data by averaging into bins
[~,out_data] =  gen_avg_curve(sel_data.speed_rpm, sel_data, 100, 50);

% Begin constructing curve by selecting points with largest error
% sel_avg_pts = build_curve(avg_data.speed_rpm,avg_data.torque_Nm, 0.005 * engine.max_torque_Nm);

% out_data = avg_data(sel_avg_pts,:);


%% Flot result
fig = figure('Visible',show_figs);

% Set boundaries 
plot_bound.min_speed_rpm = 0.95 *  engine.idle_speed_rpm;
plot_bound.max_speed_rpm = 1.05 *  engine.max_power_speed_rpm;


% Set plot area
ax = axes('Position',[0.14, 0.11, 0.765, 0.74]);
xlim([plot_bound.min_speed_rpm, plot_bound.max_speed_rpm]);
% ylim([plot_bound.min_torque_Nm, plot_bound.max_torque_Nm]);
hold on;
grid on;
set(ax,'Layer','top');
set(ax,'SortMethod','ChildOrder')


	
    % Show Data Location Points
	superplot( raw_data{~sel_pts,'speed_rpm'},  raw_data{~sel_pts,'torque_Nm'}, 'rx');
	
	superplot( sel_data.speed_rpm,	sel_data.torque_Nm, 'y.3');
	
	superplot( out_data.speed_rpm,	out_data.torque_Nm,'lb--2');
		
	% Add Speed to x Axis
	xlabel('Speed (RPM)','FontSize',11);

	% Add Title
	titlestr = sprintf('%s\nMinimum Torque Sweep Test\n',engine.plot_title);
    title(ax,titlestr,'interpreter','none','FontSize',12);
    
	

	% Add power lines
	powerlines('auto_refresh',false);       
	line([0;plot_bound.max_speed_rpm],[0;0],[10;10],'LineStyle','--','Color','k');

	% Add BMEP axis and Torque axis labels
	ylim_Nm = ylim;
	%from revs_plot_engine
	ax2 = axes('position',[0.095,0.11, 0.001, 0.74]);
	set(ax2,'YColor','b');
	set(ax2,'Color',get(gca,'color'));
	ylabel('{\color{black}Torque ( Nm )}       {\color{blue}BMEP ( Bar )}', 'FontSize',11);
	ylim(ax2, ylim_Nm / engine.displacement_L *(4*pi/100));
	set(ax2,'XTickLabel','');
	set(ax2,'HandleVisibility','off');

	% Add date
	add_plot_date
	

	
end

