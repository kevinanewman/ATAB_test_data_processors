function ax = plot_data_points(data_type,  spd_data, trq_data, engine, plot_bound, show_figs )

%% Make plot of all data points
figure('Visible',show_figs,'Renderer','Painters');

% Set plot area
ax = axes('Position',[0.14, 0.11, 0.765, 0.74], 'Layer','top','FontSize',12);
xlim([plot_bound.min_speed_rpm, plot_bound.max_speed_rpm]);
ylim([plot_bound.min_torque_Nm, plot_bound.max_torque_Nm]);
hold on;

       
    % Show Data Location Points
	max_raw_pts = strcmp(data_type,'MAX-raw');
	superplot( spd_data(max_raw_pts),  trq_data(max_raw_pts), 7.5, 'y.2');
	
	max_pts = strcmp(data_type,'MAX');
	superplot( spd_data(max_pts),	trq_data(max_pts), 8,'lb--2');
		
	min_raw_pts = strcmp(data_type,'MIN-raw');
	superplot( spd_data(min_raw_pts),  trq_data(min_raw_pts), 7.5, 'y.2');
		
	min_pts = strcmp(data_type,'MIN');
	superplot( spd_data(min_pts),	trq_data(min_pts), 8,'lb--2');
	
	ss_pts = strcmp(data_type,'SS AVG');
	superplot( spd_data(ss_pts),	trq_data(ss_pts), 8, 'k.4'); 
	
	ss_pts = strcmp(data_type,'SS CONT');
	superplot( spd_data(ss_pts),	trq_data(ss_pts), 8,'k.4'); 
	
	ss_pts = strcmp(data_type,'SS AVG TXMN');
	superplot( spd_data(ss_pts),	trq_data(ss_pts), 8,'or.4'); 
	
	ss_pts = strcmp(data_type,'SS CONT TXMN');
	superplot( spd_data(ss_pts),	trq_data(ss_pts), 8,'or.4'); 
	
	hlf_pts = strcmp(data_type,'HL-final');
	superplot(spd_data(hlf_pts),	trq_data(hlf_pts), 8, 'lglg^4');
	
	hli_pts = strcmp(data_type,'HL-initial');
	superplot(spd_data(hli_pts),	trq_data(hli_pts), 8,'lblb^4');
	   

	% Add manufacturer full throttle
	if ~all(isnan(engine.published_wot_speed_rpm)  | isnan(engine.published_wot_torque_Nm))
		% Plot WOT line provied in config txt file
		superplot( engine.published_wot_speed_rpm, engine.published_wot_torque_Nm,7, 'k--2');
	elseif ~isnan(engine.max_power_kW) && ~isnan(engine.max_power_speed_rpm) 	&& ~isnan(engine.max_torque_Nm) && ~isnan(engine.max_torque_speed_rpm)
		superplot( engine.max_power_speed_rpm, (engine.max_power_kW *1000 )/( engine.max_power_speed_rpm * convert.rpm2radps),7, 'kkd7');
		superplot( engine.max_torque_speed_rpm, engine.max_torque_Nm,7, 'kkd7');
	end
		

	% Add Title - Must be 3 Lines!
    title(ax,sprintf('%s\nTest Data Points\n',engine.plot_title),'interpreter','none','FontSize',12);
	
	% Add power lines
	powerlines('auto_refresh',false,'z_offset', 10);       
	line([0;plot_bound.max_speed_rpm],[0;0],[10;10],'LineStyle','--','Color','k');

	% Add Speed to x Axis
	xlabel('Speed (RPM)','FontSize',13);
	
	% Add torque & BMEP y axis
	ylim_Nm = ax.YLim;
	ax_pos =  ax.Position + [0.01, 0, -0.01, 0];
 	ax.Position = ax_pos;
	ax2 = axes('position',[0.08, ax_pos(2), 0.001, ax_pos(4)]);
	ax2.YColor = 'b';
	ax2.Color = ax.Color;
	ylabel(ax2, '{\color{black}Torque ( Nm )}       {\color{blue}BMEP ( Bar )}', 'FontSize',13);
	ax2.YLim = ylim_Nm / engine.displacement_L *(4*pi/100);
	ax2.XTickLabel = '';
	ax2.HandleVisibility = 'off';
		
end