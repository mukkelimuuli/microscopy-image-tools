function chosen_threshold=threshold_slider(image)
        
    chosen_threshold=0;
    fig = figure;
    
    % Define initial values
    minValue = min(image(:));     % Minimum value for the slider
    maxValue = max(image(:));    % Maximum value for the slider
    initialValue=(maxValue+minValue)/2;
    % Create a slider
    
    ax1=subplot(121);

    img=combine_tracing_and_image(image,zeros(...
        size(image)),1);
    
    imshow(img,'Parent',ax1)
    title(ax1,'Original image');
    
    ax2=subplot(122);
    new_im=image;
    new_im(new_im <=initialValue ) = 0;


    new_im=combine_tracing_and_image(new_im,zeros(...
        size(new_im)),1);
    imshow(new_im,'Parent',ax2);       % Update the plot
    title(ax2,"Current threshold")
    
    % Create a text label to display the value
    valueLabel = uicontrol('Style', 'text', ...
                           'Position', [260, 40, 60, 20], ...
                           'FontSize',12,...
                           'String', num2str(initialValue));
    
    slider = uicontrol('Style', 'slider', ...
                       'Min', minValue, 'Max', maxValue, ...
                       'Value', initialValue, ...
                       'Position', [100, 10, 350, 20], ...
                       'Callback', @(src, event) updatePlot(src, event,ax2,valueLabel));
    
    
    button= uicontrol('Style','pushbutton',...
        'Position',[500, 10, 40, 30], ...
        'BackgroundColor','b',...
        'String',"Save", ...
        'FontSize',10,...
        'Callback',@(src,event) buttonCallBack(src, event,fig,valueLabel));
    


    uiwait(fig)

    function updatePlot(source,~,ax2,valueLabel)
    
        value = source.Value; % Get the current slider value
        valueLabel.String= num2str(int32(value));
        %y = sin(value * t);   % Update your variable (e.g., amplitude)
        new_image=image;
        new_image(new_image <=value ) = 0;


        new_image=combine_tracing_and_image(new_image,zeros(...
            size(new_image)),1);
        imshow(new_image,'Parent',ax2);       % Update the plot
        title(ax2,"Current threshold")
        
    end
    
    % Callback functions for save button
    function buttonCallBack(~, ~,fig,valueLabel)
        chosen_threshold=str2double(valueLabel.String);
        close(fig);
        return
    end
end
