function z = toggleZoom(toolObj, eventdata)
handles = guidata(toolObj);
z = zoom(handles.figure1);
z.setAllowAxesZoom(handles.axes1, true);
z.setAllowAxesZoom(handles.axes2, false);

zoomstate = toolObj.State;
set([handles.uitoggletool1, handles.uitoggletool2], 'state', 'off');
switch zoomstate
    case 'on'
        zoomOn(toolObj.TooltipString);
    case 'off'
        zoomOff();
        
end

    function zoomOn(direction)
    set(z, 'enable', 'on');
    switch direction
        case 'Zoom In'
            set(z, 'Direction', 'in');
            handles.uitoggletool1.State = 'on';
            handles.uitoggletool2.State = 'off';
        case 'Zoom Out'
            set(z, 'Direction', 'out');
            handles.uitoggletool1.State = 'off';
            handles.uitoggletool2.State = 'on';
    end
    end


    function zoomOff()
    zoom(handles.figure1, 'off');
    handles.gui.Plotter.updateXYLim(handles.axes1);
    end
end