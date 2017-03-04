function figKeyPressFcn(hObject, eventdata, handles)
% Executes when the user has the main window in focus and presses a key on the keyboard.
disp(eventdata.Key)
z = zoom(handles.figure1);

switch eventdata.Key
    case 'escape'
        z.Enable = 'off';
        handles.gui.Plotter.updateXYLim(handles.axes1);
        
    case 'z'
        if strcmp(z.Enable, 'off')
            enableZoom(z);
            
        elseif strcmpi(z.Direction, 'in')
            z.Direction = 'out';
        else
            z.Direction = 'in';
        end
        
    case 'tab'
        gco
end
 

function enableZoom(z)
set(z, 'Enable', 'on', ...
    'Direction', 'in');
set(z.FigureHandle.WindowKeyPressFcn{2}, ...
    'WindowKeyPressFcn', @(o,e)figKeyPressFcn(o,e,guidata(z.FIgureHandle)));


function disableZoom(fig)
