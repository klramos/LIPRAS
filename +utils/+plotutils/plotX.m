% Properties needed: datatype, DisplayName, ColorOrder
function  plotX(handles, mode, varargin)
% All lines that would require re-plotting in d-space are initially not visible. They become visible
% after calling plotter.XScale.
persistent previousPlot_
try
    plotter = handles.gui.Plotter;
    filenum = handles.gui.CurrentFile;
    filenames = handles.gui.getFileNames;
    xrd = handles.profiles.xrd;
    if nargin < 2
        if isempty(previousPlot_)
            mode = plotter.Mode;
        else
            mode = previousPlot_;
        end
    else
        if isempty(previousPlot_) && isempty(mode)
            mode = 'data';
        elseif isempty(mode)
            mode = previousPlot_;
        end
    end
    
    handles.checkbox_superimpose.Value = 0;
    % try
    
    % Disable the figure while its plotting
    focusedObj = gco;
    enabledObjs = findobj(handles.figure1, 'Enable', 'on', 'style', 'listbox');
    set(enabledObjs, 'enable', 'inactive');
    
    switch lower(mode)
        case 'data'
            plotData(handles, mode);
            utils.plotutils.resizeAxes1ForErrorPlot(handles, 'data');
            previousPlot_ = 'data';
        case 'background'
            plotData(handles,mode);
            if handles.profiles.xrd.hasBackground
                plotBackgroundPoints(handles);
                plotBackgroundFit(handles);
            end
            previousPlot_ = 'background';
        case 'backgroundpoints'
            plotBackgroundPoints(handles);
            
        case 'backgroundfit'
            plotBackgroundFit(handles);
        case 'limits'
            updateLim(handles);
        case 'superimpose'
            plotSuperimposed(handles);
            utils.plotutils.resizeAxes1ForErrorPlot(handles, 'data');
        case 'fit'
%             set(handles.axes1.Children, 'visible', 'off');
            utils.plotutils.resizeAxes1ForErrorPlot(handles, 'fit');
            plotFitError(handles);
            plotFit(handles);
            previousPlot_ = 'fit';
        case 'sample'
            plotSampleFit(handles);
            previousPlot_ = 'sample';
        case 'allfits'
            plotAllFits(handles);
        case 'error'
            plotFitError(handles);
            utils.plotutils.resizeAxes1ForErrorPlot(handles, 'fit');
        case 'coeff' %TODO
            plotCoefficients(handles);
            previousPlot_ = 'coeff';
        case 'stats' %TODO
            plotFitStats(handles);
    end
        
    set(enabledObjs, 'Enable', 'on');
    currentFig = get(0,'CurrentFigure');
    if ~isempty(currentFig) && contains(currentFig.Name, 'LIPRAS') && ~isempty(focusedObj)
        if strcmpi(focusedObj.Type, 'uitable')
            uitable(focusedObj);
        elseif strcmpi(focusedObj.Style, 'listbox')
            uicontrol(focusedObj);
        end
    end
    %        handles.gui.Legend = 'reset';
    plotter.Mode = previousPlot_;
    set(handles.axes1.Children,'visible','on');
    handles.gui.Legend = 'reset';
    
    if strcmp(previousPlot_,'fit')
       set(handles.axes2.Children,'visible','on');
    end
    
catch ex
    ex.getReport
    set(enabledObjs, 'Enable', 'on');
    errordlg(ex.message)
end

% ==============================================================================

    function dataLine = plotData(handles, axx,j)
    % PLOTDATA Plots the raw data for a specified file number in axes1. 
    %     If there are lines, remove all other lines except data line
    
    if strcmp(mode,'fit')~=1
        axx = handles.axes1;
        ydata = xrd.getData(filenum);
    elseif and(strcmp(mode,'fit')==1,nargin< 3)
        axx = handles.axes1;
        ydata = xrd.getData(filenum);
    else
        ydata = xrd.getData(j);
    end
    dataLine = findobj(axx, 'tag', 'raw');
    notDataLineIdx = ~strcmpi(get(dataLine, 'DisplayName'), 'Measured Data');
    if ~isempty(dataLine)
        delete(dataLine(notDataLineIdx));
        dataLine = dataLine(~notDataLineIdx);
    end
    xdata = xrd.getTwoTheta;
    ydata = xrd.getData(filenum);
    props = {'LineStyle', '-', 'LineWidth', 1, 'MarkerFaceColor', [1 1 1], ...
        'Color', 'k', 'Visible', 'on', 'MarkerSize', 5};
    if isvalid(dataLine)
        set(dataLine, ...
            'XData', xdata, ...
            'YData', ydata, ...
            props{:});
        setappdata(dataLine, 'xdata', xdata);
        setappdata(dataLine, 'ydata', ydata);
        handles.gui.Plotter.transform(dataLine);
        
    elseif nargin==4
        dataLine = plotter.plotRawData(axx, ...
                            'LineStyle', '-', ...
                            'LineWidth', 1, ...
                            'MarkerFaceColor', [1 1 1], ...
                            'Color', 'k', ...
                            'Visible', 'on');
                              
        set(dataLine, 'XData', xdata, 'YData', ydata);
        setappdata(dataLine, 'xdata', xdata);
        setappdata(dataLine, 'ydata', ydata);
        handles.gui.Plotter.transform(dataLine);
    else
        dataLine = plotter.plotRawData(axx, props{:});
    end
    plotter.updateXYLim(axx,mode);
    end
% ==============================================================================


    function plotFit(handles, ax, fileID)
    % Plots the current fit in handles.axes1
    import utils.plotutils.*
    if nargin < 2
        ax = handles.axes1;
        fileID = filenum;
    end
    fitted = handles.profiles.getProfileResult{fileID};
    set(ax.Children, 'visible', 'off');
    dataLine = findobj(ax, 'tag', 'raw');
    dataprops = {'LineStyle', 'none', ...
        'MarkerSize', 4, ...
        'MarkerFaceColor', [0 0.18 0.65], ...
        'MarkerEdgeColor', 'none',...
        'XData', fitted.TwoTheta, ...
        'YData', fitted.Intensity};
    if isempty(dataLine)
        plotter.plotRawData(ax, dataprops{:});
    else
        set(dataLine, dataprops{:});
    end
    if isequal(ax, handles.axes1)
        linkaxes([handles.axes2 handles.axes1], 'x');
    end
    if nargin < 2
        plotter.updateXYLim(handles.axes1);
    end
    
    plotter.plotBgFit(ax);
    plotter.plotOverallFit(ax,fitted);
    for ii=1:xrd.NumFuncs
        plotter.plotFittedPeak(ax,fitted,ii);
    end
    
    if ~strcmp(previousPlot_, 'fit')
        handles.gui.Legend = 'reset';
    end
    % Raw Data
    

    end
% ==============================================================================

%
    function plotFitError(handles)
    fitted = handles.profiles.getProfileResult{filenum};
    plotter.plotFitErr(handles.axes2, fitted);
    
    end
% ==============================================================================

% Plot an example fit using the starting values from table.
    function handles = plotSampleFit(handles)
    import ui.control.*
    import utils.plotutils.*
    if ~strcmpi(plotter.Mode, 'sample')
        cla(handles.axes1);
    end
    plotData(handles);
    plotter.plotBgFit(handles.axes1);
    if ~plotter.canPlotSample
        return
    end
    
    % Plot background fit
    for i=1:xrd.NumFuncs
        plotter.plotSamplePeak(handles.axes1, i);
    end
    utils.plotutils.resizeAxes1ForErrorPlot(handles, 'data');
    handles.gui.Legend = 'on';
    handles.gui.Legend = 'reset';
    plotter.updateXYLim(handles.axes1,'sample'); % this always comes from sample
    end
% ==============================================================================

    function plotSuperimposed(handles)
    % Like plotData, except turns on hold to enable multiple
    %    data to be plotted in handles.axes1.
    import utils.plotutils.*
    if ~ishold(handles.axes1)
        hold(handles.axes1, 'on');
    end
    lines = handles.axes1.Children;
    %     If there are lines, remove all other lines except data line
    notDataLineIdx = ~strcmpi(get(lines, 'tag'), 'superimposed');
    if ~isempty(lines)
        delete(lines(notDataLineIdx));
    end
    set(handles.axes1.Children, 'visible', 'off');
    handles.checkbox_superimpose.Value = 1;
    activeFileLinePlot = findobj(handles.axes1, 'DisplayName', filenames{filenum});
    if isempty(activeFileLinePlot)
        % If not already plotted, add to plot
        plotter.plotRawData(handles.axes1,...
                            'Tag', 'superimposed', ...
                            'LineStyle',':',...
                            'LineWidth', 0.8,...
                            'DisplayName',filenames{filenum}, ...
                            'MarkerFaceColor', 'none');
        % If already plotted && is not the only plotted data, delete line
    else
        if length(handles.axes1.Children) > 1
            delete(activeFileLinePlot);
        end
    end
    handles.gui.Legend = 'on';
    handles.gui.Legend = 'reset';
    plotter.updateXYLim(handles.axes1);
    end
% ==============================================================================

% Makes a new figure and plots each fit for the entire dataset.
    function plotAllFits(handles)
    import utils.plotutils.*
    try
        screen = get(0, 'ScreenSize');
        nRows = floor(sqrt(xrd.NumFiles));
        nColumns = ceil(xrd.NumFiles/nRows);
        fWidth = min(400*nColumns, screen(3));
        fHeight = min(400*nRows, screen(4));
        wPos = (screen(3)-fWidth)/4;
        hPos = (screen(4)-fHeight)/4;
        delete(findall(0, 'tag', 'AllFitsFig'));
        f = figure('Name', 'Plot All Fits', ...
            'tag', 'AllFitsFig', ...
            'Units', 'pixels', ...
            'Position', [wPos hPos fWidth fHeight], ...
            'Visible', 'off');
        ax = gobjects(1,xrd.NumFiles);
        for j=1:xrd.NumFiles
            ax(j) = subplot(nRows, nColumns, j);
            if ~ishold(ax(j))
                hold(ax(j), 'on');
            end
            dataLine = plotData(handles, 'fit',ax(j),j); % 'fit' added to be specific with which function its coming from
            set(dataLine, 'LineStyle', 'none', ...
                'MarkerSize', 3.5, ...
                'MarkerFaceColor', [0 0.18 0.65]);
            plotFit(handles, ax(j), j);
            
            filename = filenames{j};
            title(ax(j), [filename ' (' num2str(j) ' of ' num2str(length(filenames)) ')'], ...
                'Interpreter', 'none', ...
                'FontSize', 14, ...
                'FontName','default');
        end
        linkaxes(ax,'xy');
        plotter.updateXYLim(ax);
        plotter.updateXLabel(ax);
        plotter.updateYLabel(ax);
        set(ax, 'box', 'on');
        set(findobj(f), 'Visible', 'on');
    catch exception
        delete(f);
        rethrow(exception)
    end
end
% ==============================================================================


    function plotCoefficients(handles)
    cla(handles.axes1)
    utils.plotutils.resizeAxes1ForErrorPlot(handles, 'data');
    hTable = handles.table_results;
    row = find(cell2mat(hTable.Data(:,1)),1);
    rowvals = cell2mat(hTable.Data(row, 2:end));
    line = plot(handles.axes1, ...
        1:xrd.NumFiles, rowvals, '-d', ...
        'MarkerSize', 8, ...
        'MarkerFaceColor', [0 0 0], ...
        'DisplayName', hTable.RowName{row});
    
    set(handles.axes1, 'XTickMode', 'auto');
    xlim(handles.axes1,[0 xrd.NumFiles+1])
    ylim(handles.axes1,'auto')
    handles.axes1.XAxis.TickLabelsMode = 'auto';
    handles.axes1.XLabel.String = 'File Number';
    handles.axes1.YLabel.String = [];
    handles.gui.Legend = 'reset';
    end
% ==============================================================================

% plots the statistics of all the fits, when 'Fit Statistics' is selected
    function plotFitStats(handles)
    hTable = handles.table_results;
    fits = handles.profiles.getProfileResult;
    numfiles = length(fits);
    
    for ii=1:numfiles
        fitted = fits{ii};
        rsquared(ii) = fitted.FmodelGOF.rsquare;
        adjrsquared(ii) = fitted.FmodelGOF.adjrsquare;
        rmse(ii) = fitted.FmodelGOF.rmse;
        obs = fitted.Intensity';
        calc = fitted.Background' + fitted.FData';
        Rp(ii) = (sum(abs(obs-calc))./(sum(obs))) * 100; %calculates Rp
        w = (1./obs); %defines the weighing parameter for Rwp
        w=w(w~=Inf); obs=obs(w~=Inf); calc=calc(w~=Inf); % Remove infinity values
        Rwp(ii) = (sqrt(sum(w.*(obs-calc).^2)./sum(w.*obs.^2)))*100 ; %Calculate Rwp
        DOF = fitted.FmodelGOF.dfe; % degrees of freedom from error
        Rexp(ii)=sqrt(DOF/sum(w.*obs.^2)); % Rexpected
        Rchi2(ii)=(Rwp/Rexp)/100; % reduced chi-squared, GOF
    end
%     
%     close(figure(5))
    scrsz = get(groot,'ScreenSize');
    figure('Name', 'Fit Statistics', 'tag', 'fitstats', 'Position',[scrsz(3)/4 scrsz(4)/4 scrsz(3)/2 scrsz(4)/2]);
    hold on
    for j=1:6
        ax(j)=subplot(2, 3, j);
    end
    
    plot(ax(1),1:numfiles, rsquared, '-ob', ...
        'MarkerSize', 8, ...
        'MarkerFaceColor', [0 0 0], ...
        'DisplayName', 'R^2')
    ylabel(ax(1),'R^2','FontSize',14);

    plot(ax(2),1:numfiles, adjrsquared, '-or', ...
        'MarkerSize', 8, ...
        'MarkerFaceColor', [0 0 0], ...
        'DisplayName', 'AdjR^2')
    ylabel(ax(2),'Adjusted R^2','FontSize',14);

    plot(ax(3),1:numfiles, rmse, '-og', ...
        'MarkerSize', 8, ...
        'MarkerFaceColor', [0 0 0], ...
        'DisplayName', 'RMSE');
    ylabel(ax(3),'Root MSE','FontSize',14);
    
    plot(ax(4),1:numfiles, Rp, '-o','Color',[0.85 0.33 0], ...
        'MarkerSize', 8, ...
        'MarkerFaceColor', [0 0 0], ...
        'DisplayName', 'Rp');
    ylabel(ax(4),'Rp','FontSize',14);
    
    plot(ax(5),1:numfiles, Rwp, '-om', ...
        'MarkerSize', 8, ...
        'MarkerFaceColor', [0 0 0], ...
        'DisplayName', 'RMSE')
    ylabel(ax(5),'Rwp','FontSize',14)
    
    plot(ax(6),1:numfiles, Rchi2, '-o', ...
        'MarkerSize', 8, ...
        'MarkerFaceColor', [0 0 0], ...
        'DisplayName', 'Reduced \chi^2')
    ylabel(ax(6),'Reduced \chi^2','FontSize',14)
    
    for ii=1:length(ax)
        xlabel(ax(ii),'File Number');
    end
    xlim(ax, [0 numfiles+1]);
    linkaxes(ax, 'x')
    end
% ==============================================================================

    function result = plotBackgroundFit(handles)
    %UNTITLED9 Summary of this function goes here
    %   Detailed explanation goes here
    if ~ishold(handles.axes1)
        hold(handles.axes1, 'on');
    end
    line = plotter.plotBgFit(handles.axes1);
    if isvalid(line) && ~isempty(line)
        result = line.YData;
    else
        result = [];
    end
    end


    function plotBackgroundPoints(handles) % plots points and BkgFit
    % The current file TODO: "getCurrentFile(handles.popup_filename)"
    if ~ishold(handles.axes1)
        hold(handles.axes1, 'on');
    end
    plotter.plotBgPoints(handles.axes1);
    end
end



