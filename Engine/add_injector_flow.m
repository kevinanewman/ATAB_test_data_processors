function data = add_injector_flow( data, inj_cal, engine )

% TODO: verify all the inputs exist

if isempty( inj_cal)
	return;
end

inj_opts(1) = struct('name', 'inj',	'dur_prefix','injector',	'fuel_prefix',	'',			'display', ''); 
inj_opts(2) = struct('name', 'gdi',	'dur_prefix','gdi',			'fuel_prefix',	'gdi_',		'display', 'GDI ');
inj_opts(3) = struct('name', 'pfi',	'dur_prefix','pfi',			'fuel_prefix',	'pfi_',		'display', 'PFI ');


% Vector for total injector flow
total_flow =zeros(height(data),1);

% Load/set baro if we need to adjust gauge / absolute
if istablevar( data, 'ambient_press')
	baro = data.ambient_press * parse_units(gettableunits(data,'ambient_press'));
else
	baro = [];
end


for i = 1:length(inj_opts)

	
	
	if ~isfield(inj_cal, [inj_opts(i).name, '_poly'])
		continue;
	end

	poly = inj_cal.( [inj_opts(i).name, '_poly'] );
	cal_type = inj_cal.( [inj_opts(i).name, '_cal_type'] );
	fuel_press_var = [inj_opts(i).fuel_prefix, 'fuel_rail_press'];
	inj_total_var = [inj_opts(i).dur_prefix, '_fuel_flow_gps'];
	inj_per_stroke_var = [inj_opts(i).dur_prefix, '_fuel_per_stroke'];
	data.(inj_total_var) = zeros(height(data),1);
	
	% Find Injector duration fields
	duration_vars = regexpcmp(data.Properties.VariableNames, [inj_opts(i).dur_prefix,'.*duration_ms']);
	duration_vars = data.Properties.VariableNames( duration_vars);
	fuel_flow_vars = strrep(  duration_vars , 'duration_ms', 'fuel_flow_gps' );

	
	if (cal_type == inj_cal_type.DIFF_PRESSURE || cal_type == inj_cal_type.RAIL_PRESSURE) && ~istablevar( data, fuel_press_var) 
		fprintf('! Unable to compute fuel flow, missing "%s"\n',fuel_press_var );
		continue;
	end	
				
	if 	cal_type == inj_cal_type.DIFF_PRESSURE && ~istablevar( data, 'intake_manifold_press')
		fprintf('! Unable to compute fuel flow, missing "intake_manifold_pressure"\n');
		continue;
	end
		
	% Calculate Injector fuel flow & add to total
	
	if cal_type == inj_cal_type.DIFF_PRESSURE
		fuel_press = data.(fuel_press_var) - convert_units( data.intake_manifold_press, gettableunits( data, 'intake_manifold_press'), gettableunits( data, fuel_press_var), 'injector calibration differential pressure', baro );
	elseif cal_type == inj_cal_type.RAIL_PRESSURE && istablevar( data, fuel_press_var)
		fuel_press = data.(fuel_press_var);
	elseif cal_type == inj_cal_type.DURATION_ONLY
		data.(fuel_press_var) = 1;		% Filler
	end
		
		
	for v = 1:length( duration_vars)
	
		fuel_specifier = data.(duration_vars{v}).* sqrt(max(0.0,fuel_press)) ;
		data.(fuel_flow_vars{v}) = max(0.0, polyval( poly, fuel_specifier) .* data.speed_rpm /(2*60*1000) ) ;	
		
		data.(inj_total_var) = data.(inj_total_var) + data.(fuel_flow_vars{v});
	end
	
	data.(inj_per_stroke_var) = 2 *1000 * data.(inj_total_var) ./ (data.speed_rpm / 60) ./ engine.num_cylinders ;
	total_flow = total_flow + data.(inj_total_var);
	
end


data.injector_fuel_flow_gps = total_flow;
data.injector_fuel_per_stroke = 2 *1000 * data.injector_fuel_flow_gps ./ (data.speed_rpm / 60) ./ engine.num_cylinders ;

