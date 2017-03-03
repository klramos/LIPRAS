classdef AxPlotter < matlab.mixin.SetGet
    %AXPLOTTER manages the different types of plot scales. Also plots individual data lines.
    properties 
        ax
        
        axerr
    end
    
    properties

    end
    
    properties (Dependent)
        Mode  % can be data, background, sample, fit, coeff, stats
        
        FileNames
        
        Title
        
        CurrentFile
        
        XScale % 'linear' or 'dspace'
        
        YScale % 'linear', 'log', or 'sqrt'
    end
    
    properties (Dependent, Hidden)
        profiles
        
        gui
    end
    
    properties (Hidden)
        
        Mode_ = 'data';
        
        XScale_ = 'linear';
        
        YScale_ = 'linear';
        
        XLim
        
        XData
        
        CurrentFileNumber_ = 1;
        
        hg_
    end
    
    properties (Hidden, Dependent)
        hg
    end
    
    methods
        function this = AxPlotter(handles)
        this.hg_ = handles;
        this.ax = handles.axes1;
        this.axerr = handles.axes2;
        % Default color order for plotting data series
        set(get(handles.axes1, 'Parent'), 'DefaultAxesColorOrder', ...
            [0      0     0;        % black
            1      0     0;        % red
            1      0.4   0;        % orange
            0.2    0.5   0;        % olive green
            0      0     0.502;    % navy blue
            0.502  0     0.502;    % violet
            0      0     1;        % royal blue
            0.502  0.502 0]);      % dark yellow
        z=zoom(handles.figure1);
        z.setAllowAxesZoom(handles.axes2, false);
        set(handles.axes1,'ColorOrder',get(handles.axes1,'DefaultAxesColorOrder'), 'LineWidth', 1);
        set([handles.axes1.XLabel], 'Interpreter', 'tex');
        set([handles.axes1.YLabel], 'Interpreter', 'tex');
        end
        % ======================================================================
        
        function set.Mode(this, mode)
        if isempty(mode)
            return
        end
        switch mode
            case 'data'
                
            case 'background'
                
            case 'sample'
                
            case 'fit'
                
            case 'coeff'
                
            case 'stats'
        end
        this.Mode_ = mode;
        end
        
        function value = get.Mode(this)
        value = this.Mode_;
        end
        
        function name = get.Title(this)
        totalfiles = length(this.FileNames);
        name = [this.FileNames{this.CurrentFile} ' (' num2str(this.CurrentFile) ...
            ' of ' num2str(totalfiles) ')'];
        end
        % ======================================================================
        
        function set.CurrentFile(this, val)
        %   VAL = a structure with field names 'Axis' and 'FileNumber'
        %
        %   VAL = an integer 
        this.hg.popup_filename.Value = val;
        this.hg.listbox_files.Value = val;
        this.hg.text_filenum.String = [num2str(val) ' of ' num2str(length(this.FileNames))];
        this.CurrentFileNumber_ = val;
        this.title;
        end
        
        function num = get.CurrentFile(this)
        num = this.CurrentFileNumber_;
        end
        
        function xdata = get.XData(this)
        twotheta = this.profiles.xrd.getTwoTheta;
        if strcmpi(this.XScale, 'linear')
            xdata = twotheta;
        else
            xdata = this.profiles.dspace(twotheta);
        end
        end
        
        function ydata = YData(this, intensity)
        if nargin < 2
            intensity = this.profiles.xrd.getData;
        end
        switch this.YScale
            case 'linear'
                ydata = intensity;
            case 'log'
                ydata = log(intensity);
            case 'sqrt'
                ydata = sqrt(intensity);
        end
        end
        
        function name = get.XScale(this)
        name = this.XScale_;
        end
        
        function set.XScale(this, type)
        this.XScale_ = type;
        this.updateXLabel(this.ax);
        this.updateXLim(this.ax);
        this.transform(this.ax.Children);
        this.transformXData_(this.axerr.Children);
        end
        % ======================================================================
        
        function set.YScale(this, type)
        this.YScale_ = type;
        this.updateYLabel(this.ax);
        this.transform(this.ax.Children);
        this.updateYLim(this.ax);
        end
        % ======================================================================
        
        function name = get.YScale(this)
        name = this.YScale_;
        end
        
        function transformXData_(this, line)
        if isempty(line), return, end
        xdata = getappdata(line, 'xdata');
        switch this.XScale
            case 'linear'
                line.XData = xdata;
            case 'dspace'
                line.XData = this.profiles.dspace(xdata);
        end
        end
        
        function transformYData_(this, line)
        if isempty(line), return, end
        ydata = getappdata(line, 'ydata');
        switch this.YScale
            case 'linear'
                set(line, 'YData', ydata);
            case 'log'
                set(line, ...
                    'XData', line.XData(ydata>0), ...
                    'YData', log(ydata(ydata>0)));
            case 'sqrt'
                set(line, ...
                    'XData', line.XData(ydata>=0), ...
                    'YData', sqrt(ydata(ydata>=0))); 
        end
        end
        
        function transform(this, lines)
        %transform transforms the line object into the appropriate scale.
        if isempty(lines), return, end
        for i=1:length(lines)
            this.transformXData_(lines(i));
            this.transformYData_(lines(i));
        end
        end
        
        function line = plotRawData(this, varargin)
        %PLOTRAWDATA plots the profile's raw data for the currently viewing file. The plotted line's
        %   'Visible' option is always initially set to 'off' so that any line conversions that
        %   might be performed will not be visible to the user. Any call to this function will
        %   always delete all other lines in the plot.
        %
        %   PLOTRAWDATA(THIS) plots the raw data with the default line options.
        %
        %   LINE = PLOTRAWDATA(THIS) returns the line object.
        %
        %   LINE = PLOTRAWDATA(THIS, AX) plots the raw data with default properties to the axis
        %   specified by AX.
        %
        %   LINE = PLOTRAWDATA(THIS, VARARGIN) plots the line with the options specified in
        %   VARARGIN to this.ax. However, if the properties 'DisplayName' and 'Tag' were specified
        %   in VARARGIN, it is not used because it will use the default property values specific
        %   only this line.
        %
        %   LINE = PLOTRAWDATA(THIS, AX, VARARGIN) plots the raw data to the axis specified by AX
        %   with properties specified by VARARGIN.
        filenum = this.gui.CurrentFile;
        x = this.profiles.xrd.getTwoTheta;
        y = this.profiles.xrd.getData(filenum);
        if nargin > 1 && isa(varargin{1}, 'matlab.graphics.axis.Axes')
            axx = varargin{1};
            if length(varargin) > 1
                varargin = varargin(2:end);
            end
        else
            axx = this.ax;
        end
        line = plot(axx,x,y,'o',...
            'DisplayName', 'Measured Data', ...
            'tag', 'raw', ...
            'MarkerFaceColor', [1 1 1], ...
            'MarkerEdgeColor', 'auto', ...
            'MarkerSize', 5, ...
            'visible', 'off');
        setappdata(line, 'xdata', x);
        setappdata(line, 'ydata', y);
        this.transform(line);
        if length(varargin) > 1
            set(line, varargin{:});
        end
        end
        
        function line = plotBgPoints(this, ax)
        line = gobjects(0);
        points = this.profiles.xrd.getBackgroundPoints;
        if isempty(points)
            return
        end
        xdata = this.profiles.xrd.getTwoTheta;
        ydata = this.profiles.xrd.getData(this.gui.CurrentFile);
        idx = utils.findIndex(xdata, points);
        line = findobj(ax, 'tag', 'background');
        if isempty(line)
            line = plot(ax, points, ydata(idx), ...
                        'rd', 'MarkerSize', 5, ...
                        'MarkerEdgeColor', 'r', ...
                        'MarkerFaceColor', 'r', ...
                        'DisplayName', 'Background',...
                        'Tag', 'background', ...
                        'Visible', 'off');
        else
            set(line, 'MarkerIndices', idx, 'MarkerFaceColor', 'r');
        end
        setappdata(line, 'xdata', line.XData);
        setappdata(line, 'ydata', line.YData);
        this.transform(line);
        end
        
        function line = plotBgFit(this, ax)
        line = findobj(ax, 'tag', 'background');
        if length(this.profiles.xrd.getBackgroundPoints) <= this.profiles.xrd.getBackgroundOrder
            if ~isempty(line), delete(line); end
            return
        end
        bkgdArray = this.profiles.xrd.calculateBackground;
        if isempty(bkgdArray)
            return
        end
        if isempty(line) || ~isvalid(line)
            line = plot(ax, this.profiles.xrd.getTwoTheta, bkgdArray,...
                '--r','LineWidth', 1, ...
                'Tag', 'background', ...
                'DisplayName', 'Background', ...
                'Visible', 'off');
        else
            set(line, ...
                'LineStyle', '--', ...
                'XData', this.profiles.xrd.getTwoTheta, ...
                'YData', bkgdArray, ...
                'Marker', 'none', ...
                'LineWidth', 1);
        end
        setappdata(line,'xdata',line.XData);
        setappdata(line,'ydata',line.YData);
        this.transform(line);
        end
        
        function line = plotSamplePeak(this, ax, fcnID)
        %plotSamplePeak Plots one peak function number specified by FCNID to the axes specified by 
        %   AX and outputs a line object. If the CuKAlpha2 peak should be calculated, it outputs two
        %   line objects.
        try
            xdata = this.profiles.xrd.getTwoTheta;
            fitsample = this.profiles.xrd.calculateFitInitial(this.gui.FitInitial.start);
            background = this.profiles.xrd.calculateBackground;
            fcnNumStr = num2str(fcnID);
            line = findobj(ax.Children, 'tag', ['sample' fcnNumStr]);
            if isempty(line)
                line = plot(ax, xdata, fitsample(fcnID,:)+background, ...
                            '--', 'LineWidth', 1, ...
                            'DisplayName', ['(' fcnNumStr ') ' this.gui.FcnNames{fcnID}], ...
                            'Tag', ['sample' fcnNumStr], ...
                            'Visible', 'off');
            else
                set(line, 'YData', fitsample(fcnID,:)+background, ...
                    'DisplayName', ['(' fcnNumStr ') ' this.gui.FcnNames{fcnID}]);
            end
            if this.profiles.CuKa
                cuKalpha2 = this.profiles.xrd.calculateCuKaPeak(fcnID);
                cukaLine = findobj([ax.Children], 'tag', ['cuka' fcnNumStr]);
                if isempty(cukaLine)
                    line(2) = plot(ax, xdata, cuKalpha2+background, ...
                                   ':','LineWidth',2,...
                                   'DisplayName',['(' fcnNumStr ') Cu-K\alpha2'], ...
                                   'Tag', ['cuka' fcnNumStr], ...
                                   'Visible', 'off');
                else
                    line(2) = cukaLine;
                    set(line(2), 'YData', cuKalpha2+background, ...
                    'DisplayName', ['(' fcnNumStr ') Cu-K\alpha2']);
                end
            end
            for i=1:length(line)
                setappdata(line(i),'xdata',line(i).XData);
                setappdata(line(i),'ydata',line(i).YData);
            end
        catch ex
            ex.getReport
            rethrow(ex)
        end
        this.transform(line);
        end
        
        function shaded = plotShadedBounds(this, ax)
        % Plots the area between the lower and upper bounds.
        if nargin < 2
            ax = this.ax;
        end
        twotheta = this.profiles.xrd.getTwoTheta;
        lower = this.gui.FitInitial.lower;
        upper = this.gui.FitInitial.upper;
        lowerY = sum(this.profiles.xrd.calculateFitInitial(lower));
        upperY = sum(this.profiles.xrd.calculateFitInitial(upper));
        y = [upperY; (upperY - lowerY)]';
        bkgd = this.profiles.xrd.calculateBackground';
        shaded = area(ax, twotheta, y+bkgd, ...
            'DisplayName', 'Fit Bounds', ...
            'tag', 'bounds', ...
            'FaceColor', 'r', ...
            'FaceAlpha', 0.4, ...
            'LineStyle', 'none');
        set(shaded(1), 'FaceColor', 'none'); % Don't display bottom area
        setappdata(shaded(1), 'xdata', shaded(1).XData);
        setappdata(shaded(1), 'ydata', shaded(1).YData);
        setappdata(shaded(2), 'xdata', shaded(2).XData);
        setappdata(shaded(2), 'ydata', shaded(2).YData);
        end
        
        function line = plotFittedPeak(this, ax, fitted, fcnID)
        %plotFittedPeak     Returns a line object that represents the fit for the function number
        %   specified by fcnID.
        fcns = fitted.FunctionNames;
        line = findobj(ax, 'tag', ['f' num2str(fcnID)]);
        if isempty(line)
            line = plot(ax, fitted.TwoTheta, fitted.FPeaks(fcnID,:)+fitted.Background, ...
                        'LineWidth',1,...
                        'DisplayName',['(' num2str(fcnID) ') ' fcns{fcnID}], ...
                        'Tag', ['f' num2str(fcnID)],...
                        'Visible', 'off');
        else
            set(line, 'XData', fitted.TwoTheta, ...
                      'YData', fitted.FPeaks(fcnID,:)+fitted.Background);
        end
        if fitted.CuKa
            kaLine = findobj(ax, 'tag', ['cuka' num2str(fcnID)]);
            if isempty(kaLine)
                line(2) = plot(ax,fitted.TwoTheta,fitted.FCuKa2Peaks(fcnID,:)+fitted.Background,...
                    ':', 'LineWidth', 2, ...
                    'DisplayName', ['Cu-K\alpha2 (Peak ', num2str(fcnID), ')'], ...
                    'Tag', ['cuka' num2str(fcnID)], ...
                    'Visible', 'off');
            else
                line(2) = kaLine(1);
                set(line(2),...
                    'XData', fitted.TwoTheta, ...
                    'YData', fitted.FCuKa2Peaks(fcnID,:)+fitted.Background, ...
                    'LineStyle', ':',...
                    'LineWidth', 2, ...
                    'DisplayName', ['Cu-K\alpha2 (Peak ', num2str(fcnID), ')'], ...
                    'Visible', 'off');
                    
            end
        end
        for i=1:length(line)
            setappdata(line(i),'xdata',line(i).XData);
            setappdata(line(i),'ydata',line(i).YData);
        end
        this.transform(line);
        end
        
        
        
        function line = plotOverallFit(this, ax, fitted)
        line = findobj(ax, 'tag', 'OverallFit');
        if isempty(line)
            line = plot(ax, fitted.TwoTheta, fitted.FData+fitted.Background, ...
                        'k','LineWidth',1,...
                        'DisplayName','Overall Fit',...
                        'Color',[0 0 0], ...
                        'Tag', 'OverallFit',...
                        'Visible', 'off'); % Overall Fit
        else
            set(line, 'XData', fitted.TwoTheta, ...
                      'YData', fitted.FData+fitted.Background);
        end
        setappdata(line,'xdata',line.XData);
        setappdata(line,'ydata',line.YData);
        this.transform(line);
        end
       
        function line = plotFitErr(this, ax, fitted)
        if nargin < 1
            ax = this.axerr;
        end
        cla(ax)
        line = plot(ax, fitted.TwoTheta, fitted.Intensity - (fitted.FData+fitted.Background), ...
                    'r', 'Tag', 'error', ...
                    'visible','off'); 
        set(ax, 'LineWidth', 1, ...
                'XLim', [min(fitted.TwoTheta) max(fitted.TwoTheta)]);
        setappdata(line,'xdata',line.XData);
        setappdata(line,'ydata',line.YData);
        this.transformXData_(line);
        end
        
        function line = plotCoeffValues(this)
        end
        
        function plotFitStats(this)
        end
        
        function updateXLabel(this, axx)
        set(axx, 'XTickMode', 'auto', 'XTickLabelMode', 'auto');
        if ~ishold(axx), hold(axx, 'on'); end
        state = warning('query', 'MATLAB:handle_graphics:exceptions:SceneNode');
        warning('off', state.identifier);
        switch this.XScale
            case 'linear'
                set([axx.XLabel], 'String', '2\theta (\circ)');
            case 'dspace'
                set([axx.XLabel], 'String', ['D-Space (' char(197) ')']);
        end
        drawnow
        warning(state.state, state.identifier);
        end
        
%         function restoreZoomState(ax, zoomstate)
%         zoomlim = getappdata(ax, 'zoom_zoomOrigAxesLimits');
%         if isempty(zoomstate)
%             % TODO
%         end
%         set(ax, 'XLim', zoomlim(1:2), 'YLim', zoomlim(3:4));
%         end
        
        function updateXLim(this, axx)
        h=guidata(axx);
        zoomstate = getappdata(h.figure1, 'ZoomOnState');
        if isequal(zoomstate, 'on')
            return
        end
        if isempty([axx.Children]), return, end
        xrange = [this.profiles.Min2T this.profiles.Max2T];
        switch this.XScale
            case 'linear'
                set(axx, 'XLim', xrange);
            case 'dspace'
                set(axx, 'XLim', sort(this.profiles.dspace(xrange)));
        end
        zoom(h.figure1, 'reset');
        end
        
        function updateYLabel(this, axx)
        %updateYAxisLabel modifies the y-axis label to display the correct title according to the
        %   y-axis scale.
        state = warning('query', 'MATLAB:handle_graphics:exceptions:SceneNode');
        warning('off', state.identifier);
        switch this.YScale
            case 'linear'
                set([axx.YLabel], 'Interpreter', 'tex', 'String', 'Intensity (a.u.)');
            case 'log'
                set([axx.YLabel], 'Interpreter', 'tex', 'String', 'ln(Intensity) (a.u.)');
            case 'sqrt'
                set([axx.YLabel], 'Interpreter', 'latex', 'String', '$$\sqrt{Intensity}$$ (a.u.)');
        end
        drawnow
        warning(state.state, state.identifier);
        end
        
        function updateYLim(this, axx)
        %updateYAxis modifies the y-axis limits based on the minimum and maximum values of the
        %   plotted lines.
        h=guidata(axx);
        zoomstate = getappdata(h.figure1, 'ZoomOnState');
        if isequal(zoomstate, 'on')
            return
        end
        if isempty([axx.Children]), return, end
        ydata = get(findobj(axx, 'tag', 'raw'), 'YData');
        if isempty(ydata)
            ydata = get(findobj(axx, 'tag', 'superimposed'), 'YData');
        end
        if iscell(ydata)
            ydata = [ydata{:}];
        elseif isempty(ydata)
            return
        end
        ydiff = max(ydata) - min(ydata);
        ymin = min(ydata)-0.05*ydiff;
        ymax = max(ydata)+0.2*ydiff;
        set(axx, 'YLim', sort([ymin ymax]));
        end
        
        function updateXYLim(this, axx,mode)
        %UPDATEXYLIM makes sure the plot is within range and displayed in the appropriate size.
        if nargin < 3
            axx = this.ax;
            mode='na';
        end
        
        this.updateXLim(axx);
        this.updateYLim(axx);
        
        this.title;
        end
        
        function title(this, varargin)
        %title Names the title of the axes.
        %
        %   TITLE(AXX) changes the title of the axes specified by AXX to the currently viewing
        %   file's name.
        %
        %   TITLE(AXX, 'FILENAME') overrides the default naming of the axes and names the axes
        %   'FILENAME' instead.
        
        if nargin > 1 && isa(varargin{1}, 'matlab.graphics.axis.Axes')
            axx = varargin{1};
            if length(varargin) > 1
                varargin = varargin(2:end);
            else
                varargin = [];
            end
        else 
            axx = this.ax;
        end
        state = warning('query', 'MATLAB:handle_graphics:exceptions:SceneNode');
        warning('off', state.identifier);
        for i=1:length(axx)
            filenum = this.CurrentFile;
            filename = this.FileNames{filenum};
            title(axx, [filename ' (' num2str(filenum) ' of ' num2str(length(this.FileNames)) ')'], ...
                'Interpreter', 'none', ...
                'FontSize', 14, 'FontName','default');
            if ~isempty(varargin)
                title(axx, varargin{:});
            end
        end
        drawnow
        warning(state.state, state.identifier);
        end
            
        
        function answer = canPlotSample(this)
        % canPlotSample returns true if the Fit Bounds table has all cells filled.
        answer = false;
        fitInitialValues = this.gui.FitInitial;
        if isempty(fitInitialValues)
            return
        end
        if isfield(fitInitialValues, 'start')
            noInput = find(fitInitialValues.start == -1, 1);
            if isempty(noInput)
                answer = true;
            end
        end 
        end
        
        function answer = canPlotFit(this)
        % canPlotFit returns true only if the dataset has been fit and the Fit Bounds table
        %   wasn't modified afterwards.
        end
        
        function answer = canPlotBackground(this)
        % canPlotBackground returns true if background points have been selected.
        end
        
        function resizePlot(this, size)
        end
        
    end
    
    methods 
        function handles = get.hg(this)
        handles = guidata(this.hg_.figure1);
        end
        
        function gui = get.gui(this)
        gui = this.hg.gui;
        end
        
        function profiles = get.profiles(this)
        profiles = this.hg.profiles;
        end
        
        function filenames = get.FileNames(this)
        filenames = this.profiles.FileNames;
        end
    end
end