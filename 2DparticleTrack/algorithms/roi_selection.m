
function window_corners=roi_selection(pic)
    window_corners=[];
    f=figure;
    imshow(pic)
    title("Select The Region of Interest by placing the rectangle")
    roi=images.roi.Rectangle(gca);
    addlistener(roi,"MovingROI",@allevents);
    addlistener(roi,"ROIMoved",@allevents);
    
    % Set the CloseRequestFcn to handle figure close event
    f.CloseRequestFcn = @closeFigure;


    draw(roi)
    if isempty(window_corners)
        error("Error: You have to select the Region of Interest " + ...
            "before closing the window!")
    end
    uiwait(f)
    
    
    function allevents(~,evt)
    evname = evt.EventName;
        switch evname
            case "MovingROI"
%                 disp("ROI moving..");
    
            case "ROIMoved"
                disp("ROI moved. Current position:  "+...
                    mat2str(evt.CurrentPosition));
                disp("Close the window after done to continue.")
                window_corners=evt.CurrentPosition;
        end
    end
    function closeFigure(src, ~)
        uiresume(src);
        delete(src);
    end
end