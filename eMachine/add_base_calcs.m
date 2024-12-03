function data  = add_base_calcs( data, data_format)

    if ~istablevar(data, 'torque_Nm') || ~istablevar(data, 'speed_rpm')
	    return
    end
    
    %% Power
    
    data.motor_power_kW = data.torque_Nm .* data.speed_rpm * convert.rpm2radps / 1000;
    
    % =IF(data.DC_power_kW > 0, 
    %   data.motor_power_kW / data.DC_power_kW * 100
    % IF(data.DC_power_kW < 0
    %   data.DC_power_kW / data.motor_power_kW * 100

    % data.motor_loss_kW = (data.AC_power_kW - data.mech_power_kW) .* sign(data.mech_power_kW);
    % data.inverter_loss_kW = (data.DC_power_kW - data.AC_power_kW) .* sign(data.mech_power_kW);

    data.motor_loss_kW = (data.AC_power_kW - data.motor_power_kW) .* sign(data.motor_power_kW);
    data.inverter_loss_kW = (data.DC_power_kW - data.AC_power_kW) .* sign(data.motor_power_kW);

    data.emot_loss_kW = data.motor_loss_kW + data.inverter_loss_kW;

    % emot_loss_kW1 = data.motor_loss_kW + data.inverter_loss_kW;
    % emot_loss_kW2 = data.DC_power_kW - data.motor_power_kW;

    data.motor_eff_pct    = 100 - data.motor_loss_kW ./ data.AC_power_kW * 100;
    data.inverter_eff_pct = 100 - data.inverter_loss_kW ./ data.DC_power_kW * 100;
    data.emot_eff_pct     = 100 - data.emot_loss_kW ./ data.DC_power_kW * 100;

    data.motor_loss_kW = abs(data.motor_loss_kW);
    data.inverter_loss_kW = abs(data.inverter_loss_kW);
    data.emot_loss_kW = data.motor_loss_kW + data.inverter_loss_kW;

    %% Uncertainty Setup

    speed_cal_uncertainty_rpm = get_cal_uncertainty(data_format, 'speed_rpm');

    torque_cal_uncertainty_Nm = get_cal_uncertainty(data_format, 'torque_Nm');
    torque_uncertainty_Nm = sqrt(torque_cal_uncertainty_Nm^2 + (data.HBM_trq_STD.^2)/60);
    
    AC_cal_uncertainty_kW = get_cal_uncertainty(data_format, 'AC_power_kW');
    DC_cal_uncertainty_kW = get_cal_uncertainty(data_format, 'DC_power_kW');

    data.emot_eff_uncertainty_pct = sqrt(data.emot_eff_pct.^2 .* ...
        ((speed_cal_uncertainty_rpm ./ data.speed_rpm).^2 + ...
        (torque_uncertainty_Nm ./ data.torque_Nm).^2 + ...
        (DC_cal_uncertainty_kW ./ data.DC_power_kW).^2));

    data.motor_eff_uncertainty_pct = sqrt(data.motor_eff_pct.^2 .* ...
        ((speed_cal_uncertainty_rpm ./ data.speed_rpm).^2 + ...
        (torque_uncertainty_Nm ./ data.torque_Nm).^2 + ...
        (AC_cal_uncertainty_kW ./ data.AC_power_kW).^2));

    data.inverter_eff_uncertainty_pct = sqrt(data.inverter_eff_pct.^2 .* ...
        ((DC_cal_uncertainty_kW ./ data.DC_power_kW).^2 + ...
        (AC_cal_uncertainty_kW ./ data.AC_power_kW).^2));
    
end


function uc_cal = get_cal_uncertainty(data_format, name)
    idx = find( strcmp( {data_format.working_name}, name), 1);        
    uc_cal = data_format(idx).calibration_uncertainty;
end


% function uc2 = get_rel_uncertainty2( data, data_format, name , num)
% 
%     idx = find( strcmp( {data_format.working_name}, name), 1);
% 
%     uc_cal = data_format(idx).calibration_uncertainty;
%     uc_oper = data_format(idx).operation_uncertainty;
%     % std_dev_name = data_format(idx).std_dev_name;
% 
%     std_dev_idx = find(strcmp( {data_format.stat_working_name}, name) & [data_format.is_cont_calc] & strcmpi({data_format.stat_calc},'STD'), 1);
%     std_dev_name = data_format(std_dev_idx).working_name;
% 
%     % 
%     % % Trace links to working names of standard deviations - for uncertainty calc
%     % 	if data_format(f).is_cont_calc && strcmpi(data_format(f).stat_calc,'STD') && ~isempty(data_format(f).stat_working_name)
%     % 		stat_working_index = strcmp( data_format(f).stat_working_name, {data_format.working_name});
%     % 		data_format(stat_working_index).std_dev_name = data_format(f).working_name;
%     % 	end
% 
%     uc2 = nan( height(data), 1);
% 
%     if isempty( idx ) || isnan( uc_cal)
% 	    return;
%     end
% 
%     if ~isempty(std_dev_name) 
% 	    if ~istablevar(data, std_dev_name)  || all(isnan(data.(std_dev_name)))
% 		    warning('Missing data for uncertainty calculation of %s linked channel has no data', name);
% 	    else
% 		    uc2 = (uc_cal.^2 +  data.(std_dev_name).^2 ./ num  ) ./ (data.(name)).^2 ;
% 	    end
%     end
% 
%     % Fill in provided operational uncertainty
%     missing = isnan( uc2);
%     if any(missing) && ~isnan( uc_oper )
% 	    default_uc2 = (uc_cal.^2 +  uc_oper.^2 ) ./ (data.(name)).^2 ;
% 	    uc2(missing) = default_uc2(missing);
%     end
% 
% end
