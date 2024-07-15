function choice=myGUI()
    % Create the main figure
    fig = figure('Name', 'Choice', 'Position', [400, 200, 600, 400]);

    % Load your background image (replace 'background.jpg' with your image file)
    bgImage = imread('morpheus_choice.jpg');

    % Create an axes for the background image
    ax = axes('Parent', fig, 'Position', [0, 0, 1, 1]);
    imshow(bgImage, 'Parent', ax);
    choiceVal=-1;
    % Create buttons
    btn1 = uicontrol('Style', 'pushbutton',...
        'BackgroundColor',[1,0,0],...
        'String', 'Automatic', 'FontSize',12,...
        'Position', [110, 75, 100, 30], 'Callback', @button1Callback);

    btn2 = uicontrol('Style', 'pushbutton',...
        'BackgroundColor',[0,0,1],...
        'String', 'Manual', 'FontSize',12,...
        'Position', [400, 75, 100, 30], 'Callback', @button2Callback);

    % Callback functions for buttons
    function choice=button1Callback(~, ~)
        choiceVal=0;
        close(fig);
    end

    function choice=button2Callback(~, ~)
        choiceVal=1;
        close(fig);
    end
    
    uiwait(fig);

    choice = choiceVal;
end

