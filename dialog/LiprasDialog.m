classdef LiprasDialog
    % Generates dialog boxes 
    properties (Constant)
        ScreenSize = get(0, 'ScreenSize');
        
    end
    
    methods (Static)
        function dlg = fittingDataSet()
        % Creates a dialog box with a Cancel button while waiting for fitting to complete.
        dPosition = LiprasDialog.centeredPosition([400 150]);
        msg = {'Peak fitting in progress. Please wait...', '', ...
                'Close this window to cancel the fit or minimize it to continue working.'};
        dlg = dialog('Name', 'Fitting Dataset...', ...
                     'Position', dPosition, ...
                     'WindowStyle', 'normal');
        uicontrol(dlg, 'Style', 'text', ...
                  'String', msg, ...
                  'FontName', 'default', ...
                  'FontSize', 11, ...
                  'Units', 'normalized', ...
                  'tag', 'text', ...
                  'Position', [0.05 0.45 0.9 0.4]);
        btnSize = [75 40];
        uicontrol(dlg, 'Style', 'pushbutton', ...
                 'Tag', 'btn', ...
                 'String', 'Cancel', ...
                 'FontName', 'default', ...
                 'FontSize', 11, ...
                 'Units', 'pixels', ...
                 'Position', [0.5*[dPosition(3)-btnSize(1), 0.6*dPosition(4)-btnSize(2)], btnSize], ...
                 'Callback', 'delete(gcf)');
        end
        
        function dlg = PolyNotUniqueWarning()
        % Issues a warning dialog when the number of background points is less than the background
        % polynomial order.
        msg = 'Polynomial is not unique; Polynomial order must be  > number of data points. Add more points to continue.';
        dlg = warndlg(msg, 'Warning');
        set(dlg, 'WindowStyle', 'modal', ...
            'WindowKeyPressFcn', 'delete(gcf)');
        end
        
        function exportPlotAsImage(handles)
        name = 'Export Plot';
        prompt = 'Select the output format:';
        listed = {'.jpg', '.png', '.tif', '.pdf'};
        okString = 'Save';
        defaultFontSize = get(0,'DefaultUIControlFontSize');
        set(0,'DefaultUIControlFontSize',11);
        [selected, ok] = listdlg('Name', name, 'SelectionMode', 'single', 'PromptString', prompt,...
            'ListString', listed, 'ListSize', [175 120], 'okstring', okString);
        set(0, 'DefaultUIControlFontSize', defaultFontSize);
        if ok
            fig = figure('position', [50 50 500 500], 'tag', 'exportplotfig', 'Visible', 'off');
            ax = copyobj(handles.axes1, fig);
            lgd = legend(ax, 'show');
            set(lgd, 'FontSize', 9, 'Box', 'off');
            set(ax.YLabel, 'FontSize', 20);
            set(ax.XLabel, 'FontSize', 20);
            set(ax.Title, 'FontSize', 24);
            outpath = [handles.profiles.Writer.OutputPath 'ExportedImages' filesep];
            oldpath = pwd;
            if ~isdir(outpath)
                mkdir(outpath);
            end
            cd(outpath);
            filename = handles.gui.FileNames{handles.gui.CurrentFile};
            [~, filename, ~] = fileparts(filename);
            switch selected
                case 1
                    print(fig, filename, '-djpeg', '-r0');
                case 2
                    print(fig, filename, '-dpng', '-r0');
                case 3
                    print(fig, filename, '-dtiff', '-r0');
                case 4
                    print(fig, filename, '-dpdf', '-r0');     
            end
            cd(oldpath);
        end
        handles.gui.PriorityStatus = 'Successfully exported plot as an image file.';
        delete(fig);
        end
        
        function pos = centeredPosition(dSize)
        % Returns a 1x2 numeric array POS of the position the dialog box of size DSIZE should be 
        %   located to be centered on the screen.
        pos = 0.5*[LiprasDialog.ScreenSize(3)-dSize(1), LiprasDialog.ScreenSize(4)-dSize(2)];
        pos = [pos dSize];
        end
    end
end