% Executes on button press of 'Select Peak(s)'.
function push_selectpeak_Callback(~,~,handles)
	handles.xrd.Status='Selecting peak positions(s)... ';
	
	oldTableData = handles.table_fitinitial.Data;
	fcns = getappdata(handles.table_paramselection, 'PSfxn');
	handles.xrd.PSfxn = handles.table_paramselection.Data(:,1)';
	
	
	
	coeff = handles.xrd.getCoeff(handles.xrd.PSfxn, handles.xrd.Constrains);
	
	peakTableRow = find(strncmp(coeff, 'x', 1));
	status='Selecting peak positions(s)... ';
	hold on
	handles.xrd.PeakPositions = [];
	
	% ginput for x position of peaks
	for i=1:length(peakTableRow)
		handles.table_fitinitial.Data(peakTableRow(i), 1:3) = {['<html><table border=0 width=150 ', ...
			'bgcolor=#FFA07A><tr><td></td></tr></table></html>']};
		
		handles.xrd.Status=[status, 'Peak ',num2str(i),'. Right click anywhere to cancel.'];
		[x,~, btn]=ginput(1);
		if btn == 3 % if the left mouse button was not pressed
			handles.table_fitinitial.Data = oldTableData;
			break
		end
		handles.xrd.PeakPositions(i) = x;
		handles.table_fitinitial.Data{peakTableRow(i),1} = x;
		handles.table_fitinitial.Data(peakTableRow(i),2:3)  = {[], []};
		
		pos=PackageFitDiffractionData.Find2theta(handles.xrd.two_theta,x);
		plot(x, handles.xrd.data_fit(1,pos), 'r*') % 'ko'
		
	end
	
	fill_table_fitinitial(handles);
	
	setappdata(handles.uipanel3, 'PeakPositions', handles.xrd.PeakPositions);
	hold off

	update_fitoptions(handles);
	set(handles.btns2, 'visible', 'on', 'selectedobject', handles.b2_toggle3);
	btns2_SelectionChangedFcn(handles.btns2, [], handles);
	
	set(handles.push_update, 'enable', 'off');
	set(handles.push_cancelupdate, 'visible', 'off');
	set(findobj(handles.panel_coeffs.Children), 'enable', 'on');
	set(handles.push_cancelupdate, 'visible', 'off');
	set(handles.b2_toggle3, 'enable', 'on');
	
	
	
	handles.xrd.Status=[handles.xrd.Status, 'Done.'];
	
	
	
	
	
