function varargout = LIPRAS(varargin)
% LIPRAS MATLAB code for LIPRAS.fig

% Last Modified by GUIDE v2.5 14-Nov-2016 10:45:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @LIPRAS_OpeningFcn, ...
    'gui_OutputFcn',  @LIPRAS_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% Executes just before LIPRAS is made visible.
function LIPRAS_OpeningFcn(hObject, eventdata, handles, varargin)
import ui.control.*
import model.*
import utils.fileutils.*

% Choose default command line output for FDGUI
handles.output = hObject;
handles.profiles = ProfileListManager.getInstance();
guidata(hObject, handles);

handles.gui = GUIController.getInstance(hObject);
handles = GUIController.initGUI(handles);

assignin('base','handles',handles);
% Update handles structure
guidata(hObject, handles);
%===============================================================================

% Outputs from this function are returned to the command line.
function varargout = LIPRAS_OutputFcn(~, ~, handles)
% Get default command line output from handles structure
varargout{1} = handles.output;
%===============================================================================

function LIPRAS_DeleteFcn(hObject, eventdata, handles)
% Executes before closing the GUI, even if the function delete() is called instead of manually 
%   closing the figure. Cleans up the workspace.
try
    delete(handles.gui);
    delete(handles.profiles);    
    % Restore previous search path
    path(getappdata(handles.figure1, 'oldpath'));
catch
end
clear('handles', 'var');

function LIPRAS_WindowButtonMotionFcn(hObject, evt, handles)
% Executes when the mouse moves inside the figure.
%
%   If it is not empty, display the TooltipString for an object in statusbarObj even when it's
%   disabled.
msg = '';
try
    obj = hittest(hObject);
    if  ~isempty(obj.TooltipString)
        msg = obj.TooltipString;
    end
catch
    try
        xx = num2str(handles.axes1.CurrentPoint(1,1));
        yy = sprintf('%.3G', handles.axes1.CurrentPoint(1,2));
        if strcmpi(class(obj), 'matlab.graphics.chart.primitive.Line')
            displayName = obj.DisplayName;
            msg = [displayName ': (' xx ', ' yy ')'];
        end
    catch
    end
end
handles.gui.Status = msg;

function LIPRAS_StatusChangedFcn(o, e, handles)
%STATUSCHANGE executes when the ProfileListManager property 'Status' is changed. 
handles.statusbarObj.setText(handles.profiles.Status);

%  Executes on button press in button_browse.
function button_browse_Callback(hObject, evt, handles)
handles.gui.PriorityStatus = 'Browsing for dataset... ';


if isfield(evt, 'test')
    isNew = handles.profiles.newXRD(evt.path, evt.filename);
else
    isNew = handles.profiles.newXRD();
end
if isNew % if not the same dataset as before
    ui.update(handles, 'dataset');
    cla(handles.axes1);
    utils.plotutils.plotX(handles, 'data');

else
    handles.gui.PriorityStatus = '';
end


function checkbox_reverse_Callback(o,e,handles)
if o.Value
    handles.gui.PriorityStatus = 'Dataset will fit in descending order.';
else
    handles.gui.PriorityStatus = 'Dataset will fit in ascending order.';
end
handles.profiles.xrd.reverseDataSetOrder;
handles.gui.reverseDataSetOrder;
utils.plotutils.plotX(handles);


%  Executes on button press in push_newbkgd.
function push_newbkgd_Callback(hObject, eventdata, handles)
%   EVENTDATA can be used to pass test values to this function to avoid any blocking calls like
%   ginput. If the number of background points is less than the background order,
%    issue a warning.
import utils.plotutils.*
plotX(handles,'data');
% handles.checkbox_superimpose.Value = 0;
handles.gui.PriorityStatus = 'Selecting background points... Press the ESC key to cancel, "Z" to toogle zoom capability, and "Enter" to finish.';
mode = get(handles.group_bkgd_edit_mode.SelectedObject, 'String');
points = selectBackgroundPoints(handles, mode);
if length(points) == 1 && isnan(points)
    utils.plotutils.plotX(handles, 'backgroundfit');
    return
end
handles.profiles.BackgroundPoints = points;

ui.update(handles, 'backgroundpoints');
utils.plotutils.plotX(handles, 'background');
if length(points) <= handles.gui.PolyOrder
    LiprasDialogCollection.PolyNotUniqueWarning;
end

function menu_xplotscale_Callback(o,e,handles)
plotter = handles.gui.Plotter;

if isa(handles.profiles.xrd.MonoWavelength,'numeric')
wave=handles.profiles.xrd.MonoWavelength;
end

switch o.Tag
    case 'menu_xaxis_linear'
        plotter.XScale = 'linear';
    case 'menu_xaxis_dspace'
        try
        answer = inputdlg('Enter wavelength (in Angstroms):', 'Input Wavelength', ...
            1, {num2str(wave(end))}, struct('Interpreter', 'tex'));
        catch
        answer = inputdlg('Enter wavelength (in Angstroms):', 'Input Wavelength', ...
            1, {'1.5406'}, struct('Interpreter', 'tex'));
        end
        
        
        if isempty(answer)
            return
        elseif ~isnan(str2double(answer{1}))
            handles.profiles.KAlpha1 = str2double(answer{1});
        else
            errordlg('You did not input a valid number.', 'Invalid Wavelength')
            return
        end
        plotter.XScale = 'dspace';
end
set(findobj(o.Parent), 'Checked', 'off'); % turn off checks in all x plot menu items
o.Checked = 'on';

function menu_yplotscale_Callback(o,e,handles)
%MENU_YPLOTSCALE_CALLBACK executes when any option under 'Plot'->'Y-Axis Scale' menu is clicked. The
%   default selection is 'menu_ylinear'.
set(findobj(o.Parent), 'Checked', 'off'); % turn off checks in all x plot menu items
o.Checked = 'on';
plotter = handles.gui.Plotter;
switch o.Tag
    case 'menu_ylinear' % linear
        plotter.YScale = 'linear';
        
    case 'menu_ylog'% log
        plotter.YScale = 'log';
        
    case 'menu_yroot' % d-space
        plotter.YScale = 'sqrt';    
end

% Plots the background points selected.
function push_fitbkgd_Callback(hObject, ~, handles)
import utils.plotutils.*

if Validate_bkg(handles) % checks to make sure BkgOrder is not greater than points selected
    return
end

if ~handles.gui.areFuncsReady || handles.gui.isFitDirty 
    plotX(handles, 'background');
else
    plotX(handles, 'sample');
end


function edit_min2t_Callback(~, ~, handles)
%EDIT_MIN2T_CALLBACK executes when the minimum 2theta value is changed in the GUI. 
handles.profiles.Min2T = handles.gui.Min2T;
handles.gui.Min2T = handles.profiles.Min2T;
if length(handles.profiles.BackgroundPoints) <= handles.gui.PolyOrder
    cla(handles.axes1);
    utils.plotutils.plotX(handles, 'data');
else
    utils.plotutils.plotX(handles, 'background');
end
ui.update(handles, 'backgroundpoints');

function edit_max2t_Callback(~, ~, handles)
handles.profiles.Max2T = handles.gui.Max2T;
handles.gui.Max2T = handles.profiles.Max2T;
if length(handles.profiles.BackgroundPoints) <= handles.gui.PolyOrder
    cla(handles.axes1);
    utils.plotutils.plotX(handles, 'data');
else
    utils.plotutils.plotX(handles, 'background');
end
ui.update(handles, 'backgroundpoints');

function edit_polyorder_Callback(src, ~, handles)
%BACKGROUNDORDERCHANGED Summary of this function goes here
%   Detailed explanation goes here
value = round(src.getValue);
if value == 1 && strcmpi(handles.gui.BackgroundModel, 'Spline')
   value = 2;
   handles.gui.PriorityStatus = '<html><font color="red">Spline Order must be > 1.';
end
xrd = handles.profiles.xrd;
xrd.setBackgroundOrder(value);
handles.gui.PolyOrder = value;

function popup_bkgdmodel_Callback(o, ~, handles)
handles.profiles.xrd.setBackgroundModel(o.String{o.Value});
ui.update(handles,'backgroundmodel');

% Executes on button press of any checkbox in panel_constraints.
function checkbox_constraints_Callback(o, ~, handles)
% Save new constraint as an index from panel_constraints.UserData
if o.Value
    handles.profiles.xrd.constrain(o.String);
else
    handles.profiles.xrd.unconstrain(o.String);
end
ui.update(handles, 'Constraints');

% Executes on button press in checkbox_lambda.
function checkbox_CuKa_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
    handles.profiles.xrd.CuKa=true;
    handles.profiles.xrd.KAlpha1 = handles.gui.KAlpha1;
    handles.profiles.xrd.KAlpha2 = handles.gui.KAlpha2;
    set(handles.panel_cuka,'Visible', 'on');
else
    handles.profiles.xrd.CuKa=false;
    set(handles.panel_cuka,'Visible', 'off');
end


function edit_kalpha_Callback(hObject, eventdata, handles)
ka1 = str2double(get(handles.edit_kalpha1, 'String'));
ka2 = str2double(get(handles.edit_kalpha2, 'String'));
handles.profiles.xrd.KAlpha1 = ka1;
handles.profiles.xrd.KAlpha2 = ka2;
handles.gui.KAlpha1 = ka1;
handles.gui.KAlpha2 = ka2;
utils.plotutils.plotX(handles);
handles.gui.Status = ['<html>' hObject.TooltipString ' wavelength set to ' hObject.String '.'];


% Executes on  'Update' button press.
function push_update_Callback(hObject, ~, handles)
% This function sets the table_fitinitial in the GUI to have the coefficients for the new
% user-inputted function names.
% It also saves handles.guidata into handles.xrd

% Doesnt update if BkgOrder is larger than points selected
if Validate_bkg(handles) % checks to make sure BkgOrder is not greater than points selected
    return
end
         

handles.profiles.FcnNames = handles.gui.FcnNames;
handles.profiles.FitInitial = 'default';

cla(handles.axes1);
ui.update(handles, 'fitinitial');
utils.plotutils.plotX(handles,'sample');
   
handles.gui.Legend = 'reset';

handles.gui.PriorityStatus = 'Fit options were updated.';
 


% Executes on button press of 'Select Peak(s)'.
function push_selectpeak_Callback(hObject, ~, handles)
import utils.contains
import utils.plotutils.*

if Validate_bkg(handles) % checks to make sure BkgOrder is not greater than points selected
    return
end

positions = utils.plotutils.selectPeakPoints(handles);

if length(positions) < handles.profiles.NumPeaks
    plotX(handles, 'sample');
else
    handles.profiles.PeakPositions = positions;
    handles.profiles.FitInitial = 'new';
    handles.gui.PriorityStatus = 'New peak positions are set.';
    ui.update(handles, 'peakposition');
    ui.update(handles, 'fitinitial_peakselect');
    plotX(handles, 'sample');
    handles.profiles.xrd.OriginalFitInitial=handles.profiles.xrd.FitInitial;
end

% Executes when the handles.edit_numpeaks spinner value is changed.
function edit_numpeaks_Callback(src, eventdata, handles)
%NUMBEROFPEAKSCHANGED Callback function that executes when the value of the
%   JSpinner object changes. 
% 
%   EVENTDATA can be used to pass test values to this function by creating a structure with a
%   field 'test' containing the value(s) to use.
handles.profiles.NumPeaks = src.getValue;

ui.update(handles, 'NumPeaks');
ui.update(handles, 'functions');
ui.update(handles, 'constraints');

function table_paramselection_CellEditCallback(hObject, evt, handles)
%   EVT can be used to test the GUI by passing a struct variable with the field name 'test'
%   containing the value to set. It also has the field 'Indices'.
row = evt.Indices(1);
col = evt.Indices(2);
if col == 1
    % Function change
    handles.profiles.FcnNames{row} = handles.gui.FcnNames{row};
    ui.update(handles, 'functions');
    handles.profiles.xrd.constrain(handles.gui.Constraints);
    ui.update(handles, 'constraints');
else
    % On constraint value change
    handles.profiles.xrd.unconstrain('Nxfwm');
    handles.profiles.xrd.constrain(handles.gui.ConstraintsInTable);
    ui.update(handles, 'Constraints');
end

% Executes when entered data in editable cell(s) in table_coeffvals.
function table_fitinitial_CellEditCallback(hObject, evt, handles)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
if isnan(evt.NewData)
    handles.gui.PriorityStatus = '<html><font color="red">Not a valid number.';
	hObject.Data{evt.Indices(1), evt.Indices(2)} = evt.PreviousData;
else
       handles.profiles.FitInitial = handles.gui.FitInitial;
       handles.gui.FitInitial = handles.profiles.FitInitial;
%     ui.update(handles, 'fitinitial_tableEdit'); %i dont think this is
%     needed otherwise it resets the table based on edit which is annoying
%     when editing a value of N9, x9, etc,.,,
    utils.plotutils.plotX(handles, 'sample');
end

assignin('base', 'handles', handles);
guidata(hObject,handles)

% Executes on button press in push_fitdata.
function push_fitdata_Callback(~, ~, handles)
    
if Validate_bkg(handles)
    return
end
    
% From Preferences
handles.profiles.xrd.Weights=handles.profiles.Weights;
handles.profiles.xrd.UniqueSave=handles.profiles.UniqueSave;


try
    prfn = handles.profiles.ActiveProfile;    
    fitresults = handles.profiles.fitDataSet(prfn);
    
    % this is so when switching constraints, the table wont update with fitted values until a fit is done
    handles.profiles.xrd.OriginalFitInitial.coeffs=handles.gui.FitInitial.coeffs; 
    if ~isempty(fitresults)
        ui.update(handles, 'results');
        utils.plotutils.plotX(handles,'fit');
    else
        utils.plotutils.plotX(handles,'sample');
    end
catch ME
    ME.getReport
    assignin('base','lastException',ME)
    errordlg(ME.message)
    return
end

function tool_help_ClickedCallback(hObject, evt, handles)
handles.gui.HelpMode = hObject.State;

function push_fitstats_Callback(~, ~, handles)
handles.gui.onPlotFitChange('stats');

% Executes on button press in push_viewall.
function push_viewall_Callback(hObject, eventdata, handles)
utils.plotutils.plotX(handles, 'allfits');

% Switches between different tabs in the current profile.
function push_tabswitch_Callback(hObject, e, handles)
% Switches between Tabs 1 (Setup), 2 (Parameters), and 3 (Results).
switch hObject.Tag
    case 'tab1_next'
        set(handles.tabpanel, 'Selection', 2);
    case 'tab2_prev'
        set(handles.tabpanel, 'Selection', 1);
    case 'tab2_next'
        set(handles.tabpanel, 'Selection', 3);
    case 'tab3_prev'
        set(handles.tabpanel, 'Selection', 2);		
end

%% Checkbox callback functions

function checkbox_recycle_Callback(o, ~, handles) %#ok<*DEFNU>
if get(o, 'value')
  handles.xrd.recycle_results = 1;
  handles.profiles.xrd.recycle_results=1;
else
  handles.xrd.recycle_results = 0;
  handles.profiles.xrd.recycle_results=0;

end

function checkbox_ignoreBounds_Callback(o, ~, handles) %#ok<*DEFNU>
if get(o, 'value')
  handles.xrd.ignore_bounds = 1;
  handles.profiles.xrd. ignore_bounds=1;
else
  handles.xrd.ignore_bounds = 0;
  handles.profiles.xrd.ignore_bounds=0;

end

function checkbox_BkgLS_Callback(o, ~, handles) %#ok<*DEFNU>
if get(o, 'value')
  handles.xrd.BkgLS = 1;
  handles.profiles.xrd.BkgLS=1;
else
  handles.xrd.BkgLS = 0;
  handles.profiles.xrd.BkgLS=0;

end

%% Popup callback functions

% Executes on selection change in popup_filename.
function popup_filename_Callback(hObject, eventdata, handles)
handles.gui.CurrentFile = hObject.Value;
% superimposed = get(handles.checkbox_superimpose, 'Value');
superimposed=strcmp(handles.menuPlot_superimpose.Checked,'on'); % LOL fixed
if superimposed
    utils.plotutils.plotX(handles, 'superimpose');
else
    utils.plotutils.plotX(handles);
end

function listbox_results_Callback(hObject,evt, handles)
%listbox_results_Callback executes when the selection is changed in the 
%   listbox in the Results tab.
%
%   - If 'Peak Fit' view is selected, the listbox displays a list of all
%   the files. When the selection is changed, it plots the fit for the 
%   new selection.
%   - If 'Coefficient Trends' is selected, the listbox displays a list of
%   the coefficient names. When the selection is changed, it plots the
%   coefficient values in a sequence for all files.
selectedPlotView = handles.panel_choosePlotView.SelectedObject;
selectedListItem = hObject.Value;
switch selectedPlotView
    case handles.radio_peakeqn
        handles.gui.CurrentFile = selectedListItem;
    case handles.radio_coeff
        %TODO
end
utils.plotutils.plotX(handles);

%% Toobar callback functions

function toolbar_legend_ClickedCallback(hObject, eventdata, handles)
% Toggles the legend.
if strcmpi(hObject.State,'on')
    toolbar_legend_OnCallback(hObject, eventdata, handles);
else
    toolbar_legend_OffCallback(hObject, eventdata, handles);
end

% Turns off the legend.
function toolbar_legend_OffCallback(~, ~, handles)
handles.gui.Legend = 'off';

function toolbar_legend_OnCallback(~, ~, handles)
% Turns on the legend.
handles.gui.Legend = 'on';
handles.gui.Legend = 'reset';

%% Menu callback functions
function menuPlot_superimpose_Callback(hObject, eventdata, handles)
 cla(handles.axes1)
 if strcmp(hObject.Checked,'on')
     hObject.Checked='off';
 else
 hObject.Checked='on';
 end
 % If box is checked, turn on hold in axes1
 if strcmp(hObject.Checked, 'on')
     hold(handles.axes1, 'on')
     handles.axes1.ColorOrderIndex = 1;
     utils.plotutils.plotX(handles, 'superimpose');
     handles.xrd.PriorityStatus='Superimposing raw data...';
 else
     utils.plotutils.plotX(handles);
 end
 handles.gui.Legend = 'reset';
 
function menu_save_Callback(~, ~, handles)
if handles.profiles.hasFit
    handles.profiles.exportProfileParametersFile();
end

% ---
function menu_parameter_Callback(~, evt, handles)
filename = 0;
if isfield(evt, 'test')
    filename = evt.test;
    pathName = evt.path;
else
    if handles.profiles.hasData
        filespec = fullfile(handles.profiles.OutputPath,'*.txt');
        [filename, pathName, ~]  = uigetfile(filespec,'Select Input File','MultiSelect', 'off');
    end
end
if filename ~= 0
    handles.profiles.importProfileParametersFile([pathName filename]);
    ui.update(handles, 'parameters');
end

function menu_FileResetProfile_Callback(o,e,handles)
    if isempty(handles.profiles.xrd)
        msgbox('Nothing to reset')
    else
handles.profiles.reset;
cla(handles.axes1);
ui.update(handles, 'dataset');
utils.plotutils.plotX(handles, 'data');
handles.gui.Legend = 'reset';
    end

function menu_restart_Callback(o,e,handles)
delete(handles.figure1);
fig = LIPRAS;
handles = guidata(fig);
guidata(handles.figure1, handles);

% Executes when the menu item 'Export->As Image' is clicked.
function menu_saveasimage_Callback(o,e,handles)
LiprasDialogCollection.exportPlotAsImage(handles);


function menu_preferences_Callback(o,e,handles)
    pref(o,e,handles);
    

    function pref(~,~,handles)
btnsize=30;
r1v=50;
r1h=15;
textb=10;

    d = dialog('Position',[50 700 350 200],'Name','Preferences');

    btn1 = uicontrol('Parent',d,...
           'Position',[175 10 100 btnsize],...
           'String','Close','FontSize',textb,...
           'Callback','delete(gcf)');
       
     btns = uicontrol('Parent',d,...
           'Position',[50 10 100 btnsize],...
           'String','Save to File','TooltipString','Save Preferences to a text file that is read with newly imported data','FontSize',textb,...
           'Callback',@(o,e)LIPRAS('SavePref',o,e,handles));
    
% Starting Director for Files      
    edbox1= uicontrol('Parent',d,...
           'Position',[r1h-90 r1v+45 300 btnsize],...
           'Style','text',...
           'FontSize',textb, 'String','Set Starting Directory:');
       
    btn2 = uicontrol('Parent',d,...
           'Position',[r1h+200 r1v+50 100 btnsize],...
           'FontSize',textb,'TooltipString','After selecting directory, hit "Save to File" to preserve for next LIPRAS startup',...
           'Callback',@(o,e)LIPRAS('openD',o,e,handles));
       set(btn2, 'String', '<html><center>Select Directory</center>');
       
% LSQ Weights
          edbox2= uicontrol('Parent',d,...
           'Position',[r1h-90 r1v-5 300 btnsize],...
           'Style','text',...
           'FontSize',textb, 'String','Least Squares Weights:');         
            
            pop1=uicontrol('Parent',d,...
                'Position', [r1h+200 r1v 100 btnsize],...
                'FontSize',textb,...
                'String', {'None','1/obs','1/sqrt(obs)','1/max(obs)','Linear','Sqrt','Log10'},...
                'Style','popup','TooltipString','Takes immediate effect, hit "Save to File" to preserve for next LIPRAS startup',...
                'Callback',@(o,e)LIPRAS('weight',o,e,handles));
try            
lst=handles.profiles.Weights;
catch
    lst='None';
end
if strcmp(lst,'None');id=1;
elseif strcmp(lst,'1/obs');id=2;
elseif strcmp(lst,'1/sqrt(obs)'); id=3;
elseif strcmp(lst,'1/max(obs)');id=4;
elseif strcmp(lst,'Linear'); id=5;
elseif strcmp(lst,'Sqrt'); id=6;
elseif strcmp(lst,'Log10'); id=7;
else
    id=1;
end
             set(pop1,'Value',id)
             
             
    % Unique Save      
                chkbox1 = uicontrol('Parent',d,...
           'Position',[r1h+250 r1v+97 100 btnsize],...
           'FontSize',textb,...
           'Style','checkbox','TooltipString','Generates new folder everytime a fit is conducted, takes immediate effect, hit "Save to File" to preserve for next LIPRAS startup',...
           'Callback',@(o,e)LIPRAS('uniqueSav',o,e,handles));
       try
                if handles.profiles.UniqueSave==1
                    set(chkbox1,'Value',1);
                else
                end
       catch
       end
       
          textbox3= uicontrol('Parent',d,...
           'Position',[r1h-90 r1v+90 300 btnsize],...
           'Style','text',...
           'FontSize',textb, 'String','Toggle Unique Save:');         
       
       uiwait(d)


    
    function openD(~,~,handles)
        folder_name=uigetdir;

handles.profiles.DataPath=folder_name;
 
        function SavePref(~,~,handles)
       PreferenceFile=fopen('Preference File.txt','w');
            fprintf(PreferenceFile,'%s %s\n','OpenDirectory=',handles.profiles.DataPath);
            fprintf(PreferenceFile,'%s %s\n','Weights=',handles.profiles.Weights);
            fprintf(PreferenceFile,'%s %i\n','UniqueSave=',handles.profiles.UniqueSave);

            fclose all;
            

            function weight(o, ~, handles)
                val=o.Value; % identifies what was selected
                w=o.String(val);
                try
                dd=['Setting weights to ' w];
                handles.profiles.Weights=w{:};
                disp(dd)
                catch
                    msgbox('Load Data First')
                end
           
                
                function uniqueSav(hObject,~,handles)
                val=hObject.Value; % identifies what was selected
                if val
                    try
                    handles.profiles.UniqueSave=1;
                    disp('Unique Save On')
                    catch
                        msgbox('Load Data First')
                    end
                else
                    try
                    handles.profiles.UniqueSave=0;
                    catch
                        msgbox('Load Data First')
                    end
                    disp('Unique Save Off')
                end
               


function menu_help_Callback(~,~)

choosedialog

    function choosedialog
btnsize=40;
r1v=80;
r1h=15;
textb=10;

    d = dialog('Position',[300 300 350 200],'Name','LIPRAS- Help');
    txt = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[70 120 210 40],...
           'String','Select Topic','FontSize',11);
       
    btn1 = uicontrol('Parent',d,...
           'Position',[125 10 100 btnsize],...
           'String','Close','FontSize',textb,...
           'Callback','delete(gcf)');
              
    btn2 = uicontrol('Parent',d,...
           'Position',[r1h r1v 100 btnsize],...
           'FontSize',textb,...
           'Callback',@web1);
       set(btn2, 'String', '<html><center>LIPRAS<br>Web Page</center>');
       
    btn3 = uicontrol('Parent',d,...
           'Position',[r1h+110 r1v 100 btnsize],...
           'FontSize',textb,...
           'Callback',@web2);
     set(btn3, 'String', '<html><center>Least-Squares<br>Fitting</center>');

       
      btn4 = uicontrol('Parent',d,...
           'Position',[r1h+220 r1v 100 btnsize],...
           'FontSize',textb,...
           'Callback',@web3);
            set(btn4, 'String', '<html><center>Statistics</center>');
       
    % Wait for d to close before running to completion
    uiwait(d);

        function web1(~,~)
            web('https://www.mse.ncsu.edu/research/jones/tools','-browser')
        function web2(~,~)
            web('https://www.mathworks.com/help/curvefit/least-squares-fitting.html#bq_5kr9-3','-browser')
        function web3(~,~)
            web('https://www.mathworks.com/help/curvefit/evaluating-goodness-of-fit.html','-browser')


function menu_about_Callback(~,~)
% Displays a message box
h = msgbox({'LIPRAS, version: 1.0' 'Authors: Klarissa Ramos, Giovanni Esteves, ' ...
    'Chris Fancher, and Jacob Jones' ' ' 'North Carolina State University (2016)' '' ...
    'Contact Information' 'Giovanni Esteves' 'Email: gesteves21@gmail.com' ...
    'Jacob Jones' 'Email: jacobjones@ncsu.edu'}, 'About');
hold on

set(h, 'Position',[500 440 400 300]) % posx, posy, horiz, vert
ah=get(h,'CurrentAxes');
c=get(ah,'Children');
set(c,'FontSize',10);
I=imread('Logo_R4.png');
I=flipud(I);
image(I)
truesize


function panel_choosePlotView_SelectionChangedFcn(hObject, evt, handles)
% Executes upon Plot View change in the Results tab.

switch hObject.SelectedObject
    case handles.radio_peakeqn
        handles.gui.onPlotFitChange('peakfit');
        
    case handles.radio_coeff
        handles.gui.onPlotFitChange('coeff');
        
    case handles.radio_statistics
        hObject.SelectedObject = evt.OldValue;
        handles.gui.onPlotFitChange('stats');
        
end


    function vali=Validate_bkg(handles)
        
             if length(handles.profiles.xrd.getBackgroundPoints) <= handles.profiles.xrd.getBackgroundOrder
                  d = dialog('Position',[300 500 300 120],'Name','Warning:');
        txt = uicontrol('Parent',d,...
              'Style','text',...
              'Position',[25 10 270 100],...
              'String',{'Polynomial order is greater than or equal to the number of points selected, add more background points or reduce polynomial order'},'FontSize',10);
        btn1 = uicontrol('Parent',d,...
           'Position',[100 10 100 30],...
           'String','Ok','FontSize',11,...
           'Callback','delete(gcf)');
       vali=1;
                return 
             else
                 vali=0;
            end
    

%% Close request functions
function figure1_CloseRequestFcn(~, ~, handles)
requestClose(handles);