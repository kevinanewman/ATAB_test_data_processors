function data  = add_continuous_calcs( data, engine)

% if ~istablevar( data,'torque_Nm') || ~istablevar(data,'speed_rpm')
% 	return
% end

	
% 	pwr = data.torque_Nm .* data.speed_rpm * convert.rpm2radps / 1000;
	

% %% Add Valve timing
% 
% if istablevar( data, 'intake_cam_phase' ) && istablevar( data,'exhaust_cam_phase')
% 
% 	
% data.intake_valve_open_deg = engine.intake_valve_open_deg + data.intake_cam_phase;
% data.intake_valve_closed_deg = engine.intake_valve_closed_deg + data.intake_cam_phase;
% 
% data.exhaust_valve_closed_deg = engine.exhaust_valve_closed_deg + data.exhaust_cam_phase;
% data.exhaust_valve_open_deg = engine.exhaust_valve_open_deg + data.exhaust_cam_phase;
% 
% data.valve_overlap_deg = max( data.exhaust_valve_closed_deg  - data.intake_valve_open_deg, 0.0,'includenan' );
% 
% r = engine.stroke_length_mm/2;
% l = engine.connecting_rod_length_mm;
% y = engine.crank_offset_mm;
% d = engine.bore_diameter_mm;
% vc = engine.clearance_volume_cc;
% 
% data.effective_compression_stroke_mm = r * ( sqrt( (1 + l/r).^2 - (y/r).^2) - cos( -data.intake_valve_closed_deg*pi/180) - l/r*sqrt(1-(r/l*sin( -data.intake_valve_closed_deg*pi/180) - y/l ).^2 ));
% data.effective_compression_ratio = (pi * (d/2).^2 .* data.effective_compression_stroke_mm/1000 + vc) ./ vc;
% 
% data.effective_expansion_stroke_mm = r * ( sqrt( (1 + l/r).^2 - (y/r).^2) - cos( -data.exhaust_valve_open_deg*pi/180) - l/r*sqrt(1-(r/l.*sin( -data.exhaust_valve_open_deg * pi/180) - y/l ).^2 ));
% data.effective_expansion_ratio = (pi * (d/2).^2 .* data.effective_expansion_stroke_mm/1000 + vc) ./ vc;
% 
% data.volume_ratio = data.effective_compression_stroke_mm ./ data.effective_expansion_stroke_mm;
% 
% end


end

