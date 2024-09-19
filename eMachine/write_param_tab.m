function write_param_tab( xls, sheet, data, emachine, output_type_label)

% Get List of All Used Variables
% working_vars = data.Properties.VariableNames;


AddProps = data.Properties.UserData;

% parameter_list = table;
% parameter_list.Name = data.Properties.VariableDescriptions'; %regexprep( working_vars, data_format.WorkingNameSearch, data_format.OutputNameReplace);
% parameter_list.Units = data.Properties.VariableUnits'; %data_format{format_index,'Units'};
% parameter_list.Description = {AddProps.description}'; %regexprep( working_vars, data_format.WorkingNameSearch, data_format.DescriptionReplace);
% % parameter_list.Description = regexprep( parameter_list.Description,'\$\d+','*');
% parameter_list.CalibrationStatus = {AddProps.calibration_status}'; % data_format{format_index,'CalibrationStatus'};
% 
% 
% parameter_list.Properties.VariableDescriptions = {'Name','Units','Description','Calibration Status'};


xls.add_sheet(sheet,1);


num_entries = length(data.Properties.VariableDescriptions);

xls.format('A1','ColWidth',30);
xls.format('B1','ColWidth',9);
xls.format('C1','ColWidth',110);
xls.format('D1','ColWidth',35);


xls.write({'Name','Units','Description','Measurement Type & Status *'}, 'A4');
xls.format( 'A4', 'RowHeight', 20 );
xls.format( 'A2', 'RowHeight', 20 );
xls.write(data.Properties.VariableDescriptions', 'A5');
xls.write(data.Properties.VariableUnits', 'B5');
xls.write({AddProps.description}', 'C5');
xls.write({AddProps.calibration_status}', 'D5');

xls.format( 'A5', 'FreezePane' );
xls.format('A1:C3','LineStyle','Continuous');
xls.format('D1:D3','OuterLineStyle','Continuous');
xls.format( xlsrange( 'A',4,4,num_entries+1),'LineStyle','Continuous');

xls.format( xlsrange( 'A', 1, 4,4),'Color',[0.8,0.8,0.8],'HorizAlign','Center','VertAlign','Center');
xls.format( 'all','HorizAlign','Center');
xls.format( xlsrange( 'C', 5, 1,num_entries),'HorizAlign','Left');

xls.write({'Version:'},'D1')
xls.write({char(datetime(date,'Format','MM-dd-yy'))},'D2')
xls.format('D2','NumberFormat', 'MM-dd-yy');

xls.write({[emachine.name, ' - '  output_type_label, ' Data']},'A1')
xls.format(xlsrange( 'A', 1, 3), 'MergeCells',true,'FontSize',16,'FontBold',true);

xls.write({emachine.citation},'A3')
xls.format( 'A3', 'RowHeight', 45 );
xls.format(xlsrange('A', 3, 3), 'MergeCells',true,'WrapText',true);


xls.show_excel


mt = {	'Sensor Calibrated to a Standard' 
		'Sensor Verified to a Standard'
		'Calculated Value'
		'Reference Only - Uncalibrated Sensor'
		'Reference Only - Voltage Measurement'
		'Reference Only - Digital Measurement'
		'Reference Only - CAN Data'
		'Reference Only - OBD Data'
		'Reference Only - System Generated'};


mt_descriptions = {	'Sensor Calibrated to a Standard � Added instrumentation that has been tested and adjusted to match a traceable standard' 
					'Sensor Verified to a Standard � Added Instrumentation that has been tested to confirm correlation with a traceable standard'
					'Calculated Value � Value calculated from sensor data during data post processing'
					'Reference Only � Uncalibrated Sensor � Added instrumentation for which documentation of a comparison against a traceable standard is not available'
					'Reference Only � Voltage Measurement � Direct measurement of an OEM sensor with conversion to engineering units provided via analysis of CAN/OBD data or sensor specifications'
					'Reference Only � Digital Measurement � Direct measurement of OEM digital input or output signal with conversion to engineering units provided via analysis of CAN/OBD data, engine or sensor specifications'
					'Reference Only � CAN Data � Data collected through reverse engineering raw traffic broadcast on the vehicle CAN bus'
					'Reference Only � OBD Data � Data collected through queries of the vehicle OBDII interface, potentially reverse engineered via factory scantool hardware and/or software'
					'Reference Only - System Generated - Data generated by the test automation or post-processing systems'};

used_mt = ismember( mt, {AddProps.calibration_status} );
footnote = sprintf('\n%s', mt_descriptions{ used_mt } );
footnote = sprintf('* Measurement Type & Status  Descriptions:%s', footnote);
xls.format(xlsrange( 'A', num_entries + 7, 4), 'MergeCells',true,'HorizAlign','Left','RowHeight',15*(1+sum(used_mt)));
xls.write({footnote},xlsrange('A', num_entries + 7,1,1));




end