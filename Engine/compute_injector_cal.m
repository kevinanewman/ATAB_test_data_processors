function [inj_cal, inj_cal_pdf, inj_cal_emf] = compute_injector_cal(  ss_data , engine, show_figs, out_fldr, waitbar_hand)

inj_cal = [];
inj_cal_emf = {};
inj_cal_pdf = {};


if ~istablevar(ss_data,'meter_fuel_flow_gps')
	warning('Unable to compute injector calibration missing fuel flow meter data');
	return;
end

err = false;

inj_opts(1) = struct('name', 'inj',	'dur_prefix','injector',	'fuel_prefix',	'',			'display', ''); 
inj_opts(2) = struct('name', 'gdi',	'dur_prefix','gdi',			'fuel_prefix',	'gdi_',		'display', 'GDI ');
inj_opts(3) = struct('name', 'pfi',	'dur_prefix','pfi',			'fuel_prefix',	'pfi_',		'display', 'PFI ');


% Inital empty data
regress_data = [];


% Load/set baro if we need to adjust gauge / absolute
if istablevar( ss_data, 'ambient_press')
	baro = ss_data.ambient_press * parse_units(gettableunits(ss_data,'ambient_press'));
else
	baro = [];
end


for i = 1:length(inj_opts)

duration_vars = regexpcmp(ss_data.Properties.VariableNames, [inj_opts(i).dur_prefix, '.*_pulse.?_duration_ms']);

if ~any(duration_vars)
 	cal_data(i).has_data = false;
	continue;
end

cal_data(i).has_data = true;
duration_all_units = ss_data([],duration_vars).Properties.VariableUnits;
duration_units = duration_all_units{1};

fuel_press_var = [inj_opts(i).fuel_prefix, 'fuel_rail_press'];
fuel_press_units = gettableunits(ss_data, fuel_press_var );

if ~all(strcmpi( duration_units, duration_all_units))
	fprintf('! Inconsistent units within %sinjector duration data - Unable to compute calibration\n', inj_opts(i).display);
	err = true;
	continue;
	% Continue to allow checking of other injector data
end


if istablevar( ss_data, fuel_press_var) && istablevar( ss_data, 'intake_manifold_press')
	%have rail and manifold pressure - Use rail pressure for desired units
	cal_type = inj_cal_type.DIFF_PRESSURE;
	cal_fuel_press = max(0,ss_data.(fuel_press_var) - convert_units( ss_data.intake_manifold_press, gettableunits( ss_data, 'intake_manifold_press'), gettableunits( ss_data, fuel_press_var), 'intake_manifold_press', baro ));
	cal_axis = sum(ss_data{:,duration_vars},2) .* sqrt(cal_fuel_press);
	cal_events = sum( ss_data{:,duration_vars} > 0 ,2);
	cal_axis_units = sprintf( '%s\\cdot\\surd%s', duration_units, regexprep( gettableunits( ss_data, fuel_press_var), '(A|G)$','') );
elseif istablevar( ss_data, fuel_press_var)
	cal_type = inj_cal_type.RAIL_PRESSURE;
	cal_fuel_press = max(0,ss_data.(fuel_press_var));
	cal_axis = sum(ss_data{:,duration_vars},2) .* sqrt(cal_fuel_press);
	cal_events = sum( ss_data{:,duration_vars} > 0 ,2);
	cal_axis_units = sprintf( '%s\\cdot\\surd%s', duration_units, regexprep( gettableunits( ss_data, fuel_press_var), '(A|G)$','') );
	fprintf( '! Computing injector calibration without intake manifold pressure compensation - Include "intake_manifold_press" for more accurate results\n');
else
	cal_type = inj_cal_type.DURATION_ONLY;
	cal_axis = sum(ss_data{:,duration_vars},2);
	cal_events = sum( ss_data{:,duration_vars} > 0 ,2);
	cal_axis_units = duration_units;
	fprintf( '! Computing injector calibration without fuel rail pressure - Include "%s" for more accurate results\n', [inj_opts(i).fuel_prefix, 'fuel_rail_press']);
end






cal_data(i).cal_type = cal_type;
% cal_data(i).cal_axis = cal_axis;
% cal_data(i).cal_events = cal_events;
cal_data(i).cal_axis_units = cal_axis_units;
cal_data(i).regress_idx = size(regress_data,2) +[1,2];
regress_data = [regress_data, cal_axis, cal_events];


end

%%
if err || isempty(regress_data)
	% if errored out above or no data was found bail here!
	return
end



%% Compute combined regression
inj_cal_quantity = ss_data.meter_fuel_flow_gps * 1000 * 60 *2 ./ ( ss_data.speed_rpm ) ;

% Remove Nans
remove = isnan( inj_cal_quantity) | any(isnan(regress_data), 2);
inj_cal_quantity(remove) = [];
regress_data(remove,:) = [];

% Compute regression & Uncertainty
weight = 1 + 2* (sum( regress_data(:,2:2:end),2 ) <= engine.num_cylinders );
regress_coef = (diag(weight) * regress_data) \ (weight .* inj_cal_quantity);
inj_est_quantity = regress_data * regress_coef;
regress_resid = inj_cal_quantity - inj_est_quantity;
fit_uncertainty = std( regress_resid ) / sqrt(length(inj_cal_quantity));

%% Split out individual calibrations and qty
for i = 1:length(inj_opts)
		
	% Update Waitbar
	waitbar(i/(length(inj_opts)+1), waitbar_hand);
	
	if ~cal_data(i).has_data
		continue;
	end
	
	poly = regress_coef(cal_data(i).regress_idx);
	
	plot_regress_data = regress_data(:,cal_data(i).regress_idx);
% 	plot_est_quantity = plot_regress_data * poly;
	plot_axis = plot_regress_data(:,1) ./ plot_regress_data(:,2);
	plot_quantity = (plot_regress_data * poly + regress_resid )./ plot_regress_data(:,2);
	
	temp = regress_data;
	temp(:,cal_data(i).regress_idx) = [];
	other_inj = sum( temp,2) > 0;
	multi_inj = plot_regress_data(:,2) > engine.num_cylinders;
	
	% Compute Fit
	R = corrcoef(plot_axis, plot_quantity,'rows','complete');
 	R_squared = R(2,1).^2;	
	
	
	% Plot
	fig = figure('visible',show_figs);

	ax = axes('Position',[0.08, 0.11, 0.86, 0.74]);
	x = [0,max( plot_axis) * 1.15];
	y = polyval(poly, x);

	% y = [0,max(InjCalQuantity ).* 1.15];
	% x = y./ InjCalRate +  InjCalDelay;
	superplot( x,y, 'r-'); hold on, grid on
% 	
% 	pt_hand = [];
	if ~any(other_inj)	

		pt_hand{1} = superplot(plot_axis(~other_inj & ~multi_inj),  plot_quantity(~other_inj & ~multi_inj),'lbo5','DisplayName', 'Single Injection');
		pt_hand{2} = superplot(plot_axis(~other_inj & multi_inj),  plot_quantity(~other_inj & multi_inj),'db+5','DisplayName', 'Multiple Injections');	

		legend([pt_hand{:}], 'Location','SouthEast')
	else
		
		pt_hand{1} = superplot(	plot_axis(~other_inj & ~multi_inj), plot_quantity(~other_inj & ~multi_inj),	'lbo5','DisplayName', [inj_opts(i).display, ' Only - Single Injection']);
		pt_hand{2} = superplot(	plot_axis(~other_inj & multi_inj),  plot_quantity(~other_inj & multi_inj),	'db+5','DisplayName', [inj_opts(i).display, ' Only - Multiple Injections']);	
		pt_hand{3} = superplot(	plot_axis(other_inj & ~multi_inj),  plot_quantity(other_inj & ~multi_inj),	'go5','DisplayName', 'GDI & PFI - Single Injection');
		pt_hand{4} = superplot(	plot_axis(other_inj & multi_inj),	plot_quantity(other_inj & multi_inj),	'dg+5','DisplayName', 'GDI & PFI - Multiple Injections');

		legend([pt_hand{:}], 'Location','SouthEast')
	end
	
	
	% xlim(x); 
	ax.XLim = x;
	ax.YLim(1) = 0;

	ylabel('Injection Quantity  ( mg / injection )')
 	xlabel(sprintf('Injection Specifier ( %s )', cal_data(i).cal_axis_units));

	title(sprintf('%s %s - Test Data Plots\n%sInjector Calibration\n',engine.name,engine.fuel,inj_opts(i).display ),'interpreter','none','FontSize',12);

	tb = annotation('textbox',[0.13,0.55,0.45,0.27],'String',sprintf('Slope:            %0.4f mg/%s^{ }\nOffset:           %0.4f mg^{ }\nFit Uncertainty:  %0.4f mg^{ }\nR^2:               %0.4f', poly(1), cal_data(i).cal_axis_units, poly(2) , fit_uncertainty,  R_squared),'FitBoxToText','on','BackgroundColor','w');
	tb.FontName = 'FixedWidth';
	
	add_plot_date
	
	% Save as EMF
	inj_cal_emf{end+1} = [out_fldr,inj_opts(i).display,'Injector Calibration.emf'];
	print_emf( inj_cal_emf{end} , [6,4.5]);
	
	% Save as PDF
	inj_cal_pdf{end+1} = [out_fldr,inj_opts(i).name,'_cal_temp.pdf'];
	print_pdf_usletter_landscape( inj_cal_pdf{end});
	close(gcf);
	
	% Store calibration for later use
	inj_cal.([inj_opts(i).name,'_poly']) = poly;
	inj_cal.([inj_opts(i).name,'_cal_type']) = cal_data(i).cal_type;
	
end


inj_cal.fit_uncertainty = fit_uncertainty/1000;


end