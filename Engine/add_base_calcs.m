function data  = add_base_calcs( data, data_format, engine)

if ~istablevar( data,'torque_Nm') || ~istablevar(data,'speed_rpm')
	return
end

%% BMEP & Power


data.bmep_bar = data.torque_Nm .* 4 * pi / (engine.displacement_L *100);
	
pwr = data.torque_Nm .* data.speed_rpm * convert.rpm2radps / 1000;
	


%% Uncertainty Setup

uncertainty_num_pts = max(1,floor((data.record_duration) .* ( data.speed_rpm / 120 )));

uncertainty2_torque_Nm = get_rel_uncertainty2( data, data_format, 'torque_Nm', uncertainty_num_pts);
uncertainty2_speed_rpm = get_rel_uncertainty2( data, data_format, 'speed_rpm', uncertainty_num_pts);
uncertainty2_meter_fuel_flow_gps = get_rel_uncertainty2( data, data_format, 'meter_fuel_flow_gps', uncertainty_num_pts);
uncertainty2_injector_fuel_flow_gps = get_rel_uncertainty2( data, data_format, 'injector_fuel_flow_gps', uncertainty_num_pts);

data.torque_uncertainty_Nm = sqrt( uncertainty2_torque_Nm );
data.speed_uncertaintty_rpm = sqrt( uncertainty2_speed_rpm );
data.meter_fuel_flow_uncertainty_gps = sqrt( uncertainty2_meter_fuel_flow_gps );
data.injector_fuel_flow_uncertainty_gps = sqrt( uncertainty2_injector_fuel_flow_gps); 

%% Blank out merged data 
data.merged_fuel_flow_gps = nan(size(data.speed_rpm));
data.merged_bsfc_gpkWhr = nan(size(data.speed_rpm));
data.merged_bte_pct =nan(size(data.speed_rpm));
data.merged_fuel_per_stroke = nan(size(data.speed_rpm));
data.merged_bsfc_uncertainty_gpkWhr = nan(size(data.speed_rpm));
data.merged_bte_uncertainty_pct = nan(size(data.speed_rpm));


%% Fuel Meter BSFC & BTE
if istablevar( data, 'meter_fuel_flow_gps')
	
	rmv_pts = (pwr <= 0) | (data.meter_fuel_flow_gps <= 0);
	
	data.meter_bsfc_gpkWhr = data.meter_fuel_flow_gps* 3600 ./ pwr;
	data.meter_bsfc_gpkWhr( rmv_pts ) = nan;
	
	data.meter_bte_pct = 100* pwr ./ ( data.meter_fuel_flow_gps * engine.fuel_heating_val_MJpkg );
	data.meter_bte_pct( rmv_pts) = nan;
    
    data.meter_fuel_per_stroke = 2 * 1000 * data.meter_fuel_flow_gps ./ (data.speed_rpm / 60) ./ engine.num_cylinders ;
	
	data.meter_bsfc_uncertainty_gpkWhr = data.meter_bsfc_gpkWhr .* sqrt( uncertainty2_torque_Nm + uncertainty2_speed_rpm + uncertainty2_meter_fuel_flow_gps);
	data.meter_bte_uncertainty_pct = data.meter_bte_pct .* sqrt( uncertainty2_torque_Nm + uncertainty2_speed_rpm + uncertainty2_meter_fuel_flow_gps + 3.1e-7 );
		
	% fill into merged
	empties = isnan( data.merged_fuel_flow_gps);
	data.merged_fuel_flow_gps(empties) = data.meter_fuel_flow_gps(empties);
	data.merged_bsfc_gpkWhr(empties) = data.meter_bsfc_gpkWhr(empties);
	data.merged_bte_pct(empties) = data.meter_bte_pct(empties);
	data.merged_fuel_per_stroke(empties) = data.meter_fuel_per_stroke(empties);
	data.merged_bsfc_uncertainty_gpkWhr(empties) = data.meter_bsfc_uncertainty_gpkWhr(empties);
	data.merged_bte_uncertainty_pct(empties) = data.meter_bte_uncertainty_pct(empties);
		
end

%% Fuel Injector BSFC & BTE
if istablevar( data, 'injector_fuel_flow_gps')
	
	rmv_pts = (pwr <= 0) | (data.injector_fuel_flow_gps <= 0);
	
	data.injector_bsfc_gpkWhr = data.injector_fuel_flow_gps* 3600 ./ pwr;
	data.injector_bsfc_gpkWhr( rmv_pts ) = nan;
	
	data.injector_bte_pct = 100* pwr ./ ( data.injector_fuel_flow_gps * engine.fuel_heating_val_MJpkg );
	data.injector_bte_pct( rmv_pts) = nan;
	
	
	data.injector_bsfc_uncertainty_gpkWhr = data.injector_bsfc_gpkWhr .* sqrt( uncertainty2_torque_Nm + uncertainty2_speed_rpm + uncertainty2_injector_fuel_flow_gps);
	data.injector_bte_uncertainty_pct = data.injector_bte_pct .* sqrt( uncertainty2_torque_Nm + uncertainty2_speed_rpm + uncertainty2_injector_fuel_flow_gps + 3.1e-7 );

	
	% Fill Empty Points in merged
	empties = isnan( data.merged_fuel_flow_gps);
	data.merged_fuel_flow_gps(empties) = data.injector_fuel_flow_gps(empties);
	data.merged_bsfc_gpkWhr(empties) = data.injector_bsfc_gpkWhr(empties);
	data.merged_bte_pct(empties) = data.injector_bte_pct(empties);
	data.merged_fuel_per_stroke(empties) = data.injector_fuel_per_stroke(empties);
	data.merged_bsfc_uncertainty_gpkWhr(empties) = data.injector_bsfc_uncertainty_gpkWhr(empties);
	data.merged_bte_uncertainty_pct(empties) = data.injector_bte_uncertainty_pct(empties);
	
end


%% Add Valve timing
r = engine.stroke_length_mm/2;
l = engine.connecting_rod_length_mm;
y = engine.crank_offset_mm;
d = engine.bore_diameter_mm;
vc = engine.clearance_volume_cc;

if istablevar( data, 'intake_cam_phase' ) && regexpcmp(gettableunits(data,'intake_cam_phase'), '(CAD|DEG)\s*ADV(ance)?','ignorecase')
	data.intake_valve_open_deg = engine.intake_valve_open_deg - data.intake_cam_phase;
	data.intake_valve_closed_deg = engine.intake_valve_closed_deg - data.intake_cam_phase;
elseif istablevar( data, 'intake_cam_phase' )
	data.intake_valve_open_deg = engine.intake_valve_open_deg + data.intake_cam_phase;
	data.intake_valve_closed_deg = engine.intake_valve_closed_deg + data.intake_cam_phase;
end

if istablevar( data,'exhaust_cam_phase') && regexpcmp(gettableunits(data,'exhaust_cam_phase'), '(CAD|DEG)\s*ADV(ance)?','ignorecase')
	data.exhaust_valve_closed_deg = engine.exhaust_valve_closed_deg - data.exhaust_cam_phase;
	data.exhaust_valve_open_deg = engine.exhaust_valve_open_deg - data.exhaust_cam_phase;
elseif 	istablevar( data,'exhaust_cam_phase')
	data.exhaust_valve_closed_deg = engine.exhaust_valve_closed_deg + data.exhaust_cam_phase;
	data.exhaust_valve_open_deg = engine.exhaust_valve_open_deg + data.exhaust_cam_phase;
end

if istablevar( data,'cam_phase') && regexpcmp(gettableunits(data,'cam_phase'), '(CAD|DEG)\s*ADV(ance)?','ignorecase')
	data.intake_valve_open_deg = engine.intake_valve_open_deg - data.cam_phase;
	data.intake_valve_closed_deg = engine.intake_valve_closed_deg - data.cam_phase;
	data.exhaust_valve_closed_deg = engine.exhaust_valve_closed_deg - data.cam_phase;
	data.exhaust_valve_open_deg = engine.exhaust_valve_open_deg - data.cam_phase;
elseif istablevar( data,'cam_phase') 
	data.intake_valve_open_deg = engine.intake_valve_open_deg + data.cam_phase;
	data.intake_valve_closed_deg = engine.intake_valve_closed_deg + data.cam_phase;
	data.exhaust_valve_closed_deg = engine.exhaust_valve_closed_deg + data.cam_phase;
	data.exhaust_valve_open_deg = engine.exhaust_valve_open_deg + data.cam_phase;
end


if istablevar( data,'exhaust_valve_closed_deg') && istablevar( data,'intake_valve_open_deg')
	data.valve_overlap_deg = data.exhaust_valve_closed_deg  - data.intake_valve_open_deg;
end

if istablevar( data,'intake_valve_closed_deg')
	data.effective_compression_stroke_mm = r * ( sqrt( (1 + l/r).^2 - (y/r).^2) - cos( -data.intake_valve_closed_deg*pi/180) - l/r*sqrt(1-(r/l*sin( -data.intake_valve_closed_deg*pi/180) - y/l ).^2 ));
	data.effective_compression_ratio = (pi * (d/2).^2 .* data.effective_compression_stroke_mm/1000 + vc) ./ vc;
end

if istablevar( data,'exhaust_valve_open_deg')
	data.effective_expansion_stroke_mm = r * ( sqrt( (1 + l/r).^2 - (y/r).^2) - cos( -data.exhaust_valve_open_deg*pi/180) - l/r*sqrt(1-(r/l.*sin( -data.exhaust_valve_open_deg * pi/180) - y/l ).^2 ));
	data.effective_expansion_ratio = (pi * (d/2).^2 .* data.effective_expansion_stroke_mm/1000 + vc) ./ vc;
end

if istablevar( data,'exhaust_valve_open_deg') && istablevar( data,'intake_valve_closed_deg')
	data.volume_ratio = data.effective_expansion_stroke_mm ./ data.effective_compression_stroke_mm ;
end




end


function uc2 = get_rel_uncertainty2( data, data_format, name , num)

idx = find( strcmp( {data_format.working_name}, name), 1);


uc_cal = data_format(idx).calibration_uncertainty;
uc_oper = data_format(idx).operation_uncertainty;
% std_dev_name = data_format(idx).std_dev_name;

std_dev_idx = find(strcmp( {data_format.stat_working_name}, name) & [data_format.is_cont_calc] & strcmpi({data_format.stat_calc},'STD'), 1);
std_dev_name = data_format(std_dev_idx).working_name;

% 
% % Trace links to working names of standard deviations - for uncertainty calc
% 	if data_format(f).is_cont_calc && strcmpi(data_format(f).stat_calc,'STD') && ~isempty(data_format(f).stat_working_name)
% 		stat_working_index = strcmp( data_format(f).stat_working_name, {data_format.working_name});
% 		data_format(stat_working_index).std_dev_name = data_format(f).working_name;
% 	end



uc2 = nan( height(data), 1);

if isempty( idx ) || isnan( uc_cal)
	return;
end

if ~isempty(std_dev_name) 
	if ~istablevar(data, std_dev_name)  || all(isnan(data.(std_dev_name)))
		warning('Missing data for uncertainty calculation of %s linked channel has no data', name);
	else
		uc2 = (uc_cal.^2 +  data.(std_dev_name).^2 ./ num  ) ./ (data.(name)).^2 ;
	end
end

% Fill in provided operational uncertainty
missing = isnan( uc2);
if any(missing) && ~isnan( uc_oper )
	default_uc2 = (uc_cal.^2 +  uc_oper.^2 ) ./ (data.(name)).^2 ;
	uc2(missing) = default_uc2(missing);
end

end







