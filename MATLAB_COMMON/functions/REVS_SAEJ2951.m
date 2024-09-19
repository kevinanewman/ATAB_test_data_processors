function [drive_quality_stats] = REVS_SAEJ2951( model_data, varargin )

do_plots = parse_varargs(varargin,'do_plots', false, 'toggle');
verbose  = parse_varargs(varargin,'verbose', 0,'numeric');
output_fid  = parse_varargs(varargin,'output_fid', 1,'numeric');
use_adjusted_ABC  = parse_varargs(varargin, 'use_unadjusted_ABCs', true, 'toggle');

F0_N        = model_data.vehicle.coastdown_target_A_N     + model_data.vehicle.coastdown_adjust_A_N * use_adjusted_ABC;
Fl_Npms     = model_data.vehicle.coastdown_target_B_Npms  + model_data.vehicle.coastdown_adjust_B_Npms * use_adjusted_ABC;
F2_Npms2    = model_data.vehicle.coastdown_target_C_Npms2 + model_data.vehicle.coastdown_adjust_C_Npms2 * use_adjusted_ABC;

ETW_kg      = model_data.vehicle.mass_static_kg;

Me_kg       = 1.015 * ETW_kg;

for p = 1:max(model_data.vehicle.drive_cycle_phase)
    
    pts = (model_data.vehicle.drive_cycle_phase == p);
    
    phase_time = model_data.time(pts);
    phase_time = phase_time - phase_time(1);
    
    %    time        = interp1(model_data.time, model_data.time, 0:0.1:model_data.time(end));
    time        = interp1(phase_time, phase_time, 0:0.1:phase_time(end));
    Vroll_mps   = interp1(phase_time, model_data.vehicle.speed_mps(pts), time);
    Vsched_mps  = interp1(phase_time, model_data.vehicle.drive_cycle_speed_mps(pts), time);
    
    if do_plots
        fplothg(time, Vsched_mps, 'b.-');
        plothg(time, Vroll_mps, 'r.-');
    end
    
    %% VEHICLE SPEED FILTER, FIRST PASS
    Vd_tmp_mps = zeros(size(time));
    Vt_tmp_mps = zeros(size(time));
    
    for i = 3:length(time)-2
        Vd_tmp_mps(i) = 1/5 * (Vroll_mps(i-2) + Vroll_mps(i-1) + Vroll_mps(i) + Vroll_mps(i+1) + Vroll_mps(i+2));
        Vt_tmp_mps(i) = 1/5 * (Vsched_mps(i-2) + Vsched_mps(i-1) + Vsched_mps(i) + Vsched_mps(i+1) + Vsched_mps(i+2));
    end
    
    Vd_mps = Vd_tmp_mps;
    Vt_mps = Vt_tmp_mps;
    
    %% VEHICLE SPEED FILTER, SECOND PASS
    Vd_tmp_mps = zeros(size(time));
    Vt_tmp_mps = zeros(size(time));
    
    for i = 3:length(time)-2
        Vd_tmp_mps(i) = 1/5 * ( Vd_mps(i-2) + Vd_mps(i-1) + Vd_mps(i) + Vd_mps(i+1) + Vd_mps(i+2) );
        Vt_tmp_mps(i) = 1/5 * ( Vt_mps(i-2) + Vt_mps(i-1) + Vt_mps(i) + Vt_mps(i+1) + Vt_mps(i+2) );
    end
    
    Vd_mps = Vd_tmp_mps;
    Vt_mps = Vt_tmp_mps;
    
    clear Vt_tmp_mps Vd_tmp_mps
    
    %% SPEED TRUNCATION lESS THAN OR EQUAL TO 0.03 m/s
    Vd_mps(Vd_mps <= 0.03) = 0;
    Vt_mps(Vd_mps <= 0.03) = 0;
    
    %% ROAD LOAD FORCES (Newtons)
    Frld_N = zeros(size(time));
    Frlt_N = zeros(size(time));
    for i = 1:length(time)
        Frld_N(i) = F0_N + Fl_Npms * Vd_mps(i) + F2_Npms2 * Vd_mps(i)^2; % Newtons
        Frlt_N(i) = F0_N + Fl_Npms * Vt_mps(i) + F2_Npms2 * Vt_mps(i)^2; % Newtons
    end
    
    %% ACCELERATION CALCS (m/s^2)    
    ad_mps2 = zeros(size(time));
    at_mps2 = zeros(size(time));
    for i = 2:length(time)-1
        ad_mps2(i) = (Vd_mps(i+1) - Vd_mps(i-1)) / 0.2; % Sample period is 0.1 seconds.
        at_mps2(i) = (Vt_mps(i+1) - Vt_mps(i-1)) / 0.2;
    end
    
    %% DISTANCE CALCULATIONS (meters)
    dd_m = zeros(size(time)); % Distance Increment
    dt_m = zeros(size(time));
    
    for i=2:length(time)
        dd_m(i) = Vd_mps(i) * 0.1; % mi. Sample period is 0.1 seconds.
        dt_m(i) = Vt_mps(i) * 0.1;
    end
    
    drive_quality_stats.Dd_m(p) = sum(dd_m); % Accumulated Distance
    drive_quality_stats.Dt_m(p) = sum(dt_m);
    
    %% INERTIA F0HCES (Newtons)
    Fid_N = zeros(size(time));
    Fit_N = zeros(size(time));
    
    for i = 1:length(time)
        Fid_N(i) = Me_kg * ad_mps2(i);
        Fit_N(i) = Me_kg * at_mps2(i);
    end
    
    %% INERTIAL WORK (Joules)
    IWd_J = 0;
    IWt_J = 0;
    for i=1:length(time)
        if Fid_N(i) >= 0, IWd_J = IWd_J + Fid_N(i) * dd_m(i); end
        if Fit_N(i) >= 0, IWt_J = IWt_J + Fit_N(i) * dt_m(i); end
    end
    
    %% INERTIAL WORK RATING (%)
    drive_quality_stats.IWR_pct(p) = (IWd_J-IWt_J) / IWt_J * 100;
    
    % Inertial work (J and J/m)
    drive_quality_stats.IWt_J(p) = IWt_J;
    drive_quality_stats.IWt_Jpm(p) = IWt_J / drive_quality_stats.Dt_m(p);
    drive_quality_stats.IWd_J(p) = IWd_J;
    drive_quality_stats.IWd_Jpm(p) = IWd_J / drive_quality_stats.Dd_m(p);

    %% "ENGINE" FORCE (Newtons)
    Fengd_N = zeros(size(time));
    Fengt_N = zeros(size(time));
    
    for i=1:length(time)
        if Frld_N(i) + Fid_N(i) >= 0
            Fengd_N(i) = (Frld_N(i) + Fid_N(i));
        else
            Fengd_N(i) = 0;
        end
        
        if Frlt_N(i) + Fit_N(i) >= 0
            Fengt_N(i) = (Frlt_N(i) + Fit_N(i) );
        else
            Fengt_N(i) = 0;
        end
    end
    
    %% ENGINE WCRK (Joules)
    Wengd_J = zeros(size(time));
    Wengt_J = zeros(size(time));

    for i=1:length(time)
        Wengd_J(i) = Fengd_N(i) * dd_m(i);
        Wengt_J(i) = Fengt_N(i) * dt_m(i);
    end

    % roadload required energy (Joules)
    Wrld_J = zeros(size(time));
    Wrlt_J = zeros(size(time));

    for i=1:length(time)
        Wrld_J(i) = Frld_N(i) * dd_m(i);
        Wrlt_J(i) = Frlt_N(i) * dt_m(i);
    end
    
    %% CYCLE ENERGY (Joules)
    drive_quality_stats.CEd_J(p) = sum( Wengd_J );
    drive_quality_stats.CEt_J(p) = sum( Wengt_J );
    
    % roadload cycle energy (Joules)
    drive_quality_stats.CErld_J(p) = sum( Wrld_J );
    drive_quality_stats.CErlt_J(p) = sum( Wrlt_J );

    % roadload work required from engine
    drive_quality_stats.EngCErlt_J(p) = drive_quality_stats.CEt_J(p) - drive_quality_stats.IWt_J(p);
    drive_quality_stats.EngCErld_J(p) = drive_quality_stats.CEd_J(p) - drive_quality_stats.IWd_J(p);
    
    %% ENERGY RATING (%)
    drive_quality_stats.ER_pct(p) = (drive_quality_stats.CEd_J(p) - drive_quality_stats.CEt_J(p)) / drive_quality_stats.CEt_J(p) * 100;
    
    %% DISTANCE Rating (%)
    drive_quality_stats.DR_pct(p) = (drive_quality_stats.Dd_m(p) - drive_quality_stats.Dt_m(p)) / drive_quality_stats.Dt_m(p) * 100;
    
    %% ENERGY ECONOMY RATING (%)
    drive_quality_stats.EER_pct(p) = (1-( ((drive_quality_stats.DR_pct(p)/100)+1) / ((drive_quality_stats.ER_pct(p)/100)+1)) ) * 100;
    
    %% ABSOLUTE SPEED CHANGE METRIC (m/s^2)
    drive_quality_stats.ASCd_mps2(p) = 0;
    drive_quality_stats.ASCt_mps2(p) = 0;
    for i=1:length(time)
        drive_quality_stats.ASCd_mps2(p) = drive_quality_stats.ASCd_mps2(p) + abs(ad_mps2(i));
        drive_quality_stats.ASCt_mps2(p) = drive_quality_stats.ASCt_mps2(p) + abs(at_mps2(i));
    end
    clear i
    
    drive_quality_stats.ASCd_mps2(p) = drive_quality_stats.ASCd_mps2(p) * 0.1; % Sample period is 0.1 seconds.
    drive_quality_stats.ASCt_mps2(p) = drive_quality_stats.ASCt_mps2(p) * 0.1;
    
    %% ABSOLUTE SPEED CHANGE RATING (%)
    drive_quality_stats.ASCR_pct(p) = (drive_quality_stats.ASCd_mps2(p) - drive_quality_stats.ASCt_mps2(p)) / drive_quality_stats.ASCt_mps2(p) * 100;
    
    %% ASC PER TIME
    ASCtime = drive_quality_stats.ASCt_mps2(p) / (length(time)*0.1); % meter per second per second.
    
    %% ROOT MEAN SQUARED SPEED ERROR
    spd_error_m2ps2 = zeros(size(time));
    for i=1:length(time)
        spd_error_m2ps2(i) = (Vd_mps(i) - Vt_mps(i))^2; %In mps
    end
    
    drive_quality_stats.RMSSE_mph(p) = 2.237 * sqrt(sum(spd_error_m2ps2) / length(time)); %, The 2.237 is tcJ convert to mph
    clear spd_error
    
    %% CYCLE ENERGY INTENSITY
    drive_quality_stats.CEt_dist_Jpm(p) = drive_quality_stats.CEt_J(p) / drive_quality_stats.Dt_m(p);
    drive_quality_stats.CEd_dist_Jpm(p) = drive_quality_stats.CEd_J(p) / drive_quality_stats.Dd_m(p);

    % cycle roadload demand
    drive_quality_stats.CErlt_dist_Jpm(p) = drive_quality_stats.CErlt_J(p) / drive_quality_stats.Dt_m(p);
    drive_quality_stats.CErld_dist_Jpm(p) = drive_quality_stats.CErld_J(p) / drive_quality_stats.Dd_m(p);

    % required roadload demand
    drive_quality_stats.EngCErlt_dist_Jpm(p) = drive_quality_stats.EngCErlt_J(p) / drive_quality_stats.Dt_m(p);
    drive_quality_stats.EngCErld_dist_Jpm(p) = drive_quality_stats.EngCErld_J(p) / drive_quality_stats.Dd_m(p);

    %% INERTIAL WORK FRACTION
    drive_quality_stats.IWF_norm(p) = IWt_J / drive_quality_stats.CEt_J(p); %unitless quantity
    
    %ROAD LOAD WORK FRACTION
    drive_quality_stats.RLWF_norm(p) = 1 - drive_quality_stats.IWF_norm(p); % unitless quantity
    
    %% POWER
    Pt_W = zeros(size(time));
    for i=2:length(time)
        Pt_W(i) = Fengt_N(i) * Vt_mps(i);
    end

    Pd_W = zeros(size(time));
    for i=2:length(time)
        Pd_W(i) = Fengd_N(i) * Vd_mps(i);
    end

    %% ABSOLUTE POWER CHANGE
    powert_deriv_tmp_W = zeros(size(time));
    for i = 2:length(time)-1
        powert_deriv_tmp_W(i) = abs((Pt_W(i+1)-Pt_W(i-1)) / 0.2);
    end
    powert_deriv_tmp_W(end) = Pt_W(end);
    
    drive_quality_stats.APC(p) = sum(powert_deriv_tmp_W) * 0.1;
    clear powert_deriv_tmp
    
    %% ABSOLUTE POWER CHANGE PER TIME
    drive_quality_stats.time_secs(p) = length(time)*0.1; % Sample period is 0.1 seconds.
    drive_quality_stats.APCtime(p) = drive_quality_stats.APC(p) / drive_quality_stats.time_secs(p); 
    
    % Saving
    %Vehicle_Name = char(char(Name));
    
    if verbose
        fprintf(output_fid, 'SAE J2951 Drive Quality Metrics:\n');
        %fprintf(fid, 'Vehicle Name %s\n',Vehicle_Name);
        %fprintf(fid, '%s\n',(ID) );
        fprintf(output_fid, 'Time secs         %f\n', drive_quality_stats.time_secs(p));
        fprintf(output_fid, 'CEt MJ            %f\n',(drive_quality_stats.CEt_J(p)/10^6) );
        fprintf(output_fid, 'CEt_dist J/m      %f\n',(drive_quality_stats.CEt_dist_Jpm(p)) );
        fprintf(output_fid, 'CEd MJ            %f\n',(drive_quality_stats.CEd_J(p)/10^6) );
        fprintf(output_fid, 'CEd_dist J/m      %f\n',(drive_quality_stats.CEd_dist_Jpm(p)) );
        fprintf(output_fid, 'ER %%             %2.2f\n',(drive_quality_stats.ER_pct(p)));
        fprintf(output_fid, 'DR %%             %2.2f\n',(drive_quality_stats.DR_pct(p)) );
        fprintf(output_fid, 'EER %%            %2.2f\n',(drive_quality_stats.EER_pct(p)));
        fprintf(output_fid, 'ASCt              %f\n',(drive_quality_stats.ASCt_mps2(p) / 1000));
        fprintf(output_fid, 'ASCd              %f\n',(drive_quality_stats.ASCd_mps2(p) / 1000));
        fprintf(output_fid, 'ASCR %%           %2.2f\n',(drive_quality_stats.ASCR_pct(p)));
        fprintf(output_fid, 'Dt mi             %f\n',(drive_quality_stats.Dt_m(p)/1609.344));
        fprintf(output_fid, 'Dt m              %f\n', drive_quality_stats.Dt_m(p));
        fprintf(output_fid, 'Dd mi             %f\n',(drive_quality_stats.Dd_m(p)/1609.344));
        fprintf(output_fid, 'Dd m              %f\n', drive_quality_stats.Dd_m(p));
        fprintf(output_fid, 'Distance Error mi %f\n' , (drive_quality_stats.Dt_m(p) - drive_quality_stats.Dd_m(p))/1609.344 );
        fprintf(output_fid, 'RMSSE_mph         %f\n',(drive_quality_stats.RMSSE_mph(p)));
        
        fprintf(output_fid, '---  supplemental stats ---\n');
        fprintf(output_fid, 'IWt MJ            %f\n', (drive_quality_stats.IWt_J(p)/10^6) );
        fprintf(output_fid, 'IWt dist J/m      %f\n', (drive_quality_stats.IWt_Jpm(p)) );
        fprintf(output_fid, 'IWd MJ            %f\n', (drive_quality_stats.IWd_J(p)/10^6) );
        fprintf(output_fid, 'IWd dist J/m      %f\n', (drive_quality_stats.IWd_Jpm(p)) );        
        fprintf(output_fid, 'CErlt MJ            %f\n', (drive_quality_stats.CErlt_J(p)/10^6) );
        fprintf(output_fid, 'CErlt_dist J/m      %f\n', (drive_quality_stats.CErlt_dist_Jpm(p)) );
        fprintf(output_fid, 'CErld MJ            %f\n', (drive_quality_stats.CErld_J(p)/10^6) );
        fprintf(output_fid, 'CErld_dist J/m      %f\n', (drive_quality_stats.CErld_dist_Jpm(p)) );
        fprintf(output_fid, 'EngCErlt MJ            %f\n', (drive_quality_stats.EngCErlt_J(p)/10^6) );
        fprintf(output_fid, 'EngCErlt_dist J/m      %f\n', (drive_quality_stats.EngCErlt_dist_Jpm(p)) );
        fprintf(output_fid, 'EngCErld MJ            %f\n', (drive_quality_stats.EngCErld_J(p)/10^6) );
        fprintf(output_fid, 'EngCErld_dist J/m      %f\n', (drive_quality_stats.EngCErld_dist_Jpm(p)) );

        %fprintf(fid, '%f\n' ,(NEC) );
        %fprintf(fid,'%f\n',(FC));
        fprintf(output_fid,'\n');
        % fclose (fid) ;
    end
    
end
