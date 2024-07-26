function [fullPathsCell,lastThreeChars]=while_file_selection(varargin)
    
    % A while loop of asking the user to select files until cancel or exit
    % is pressed to continue with the file
    fullPathsCell = {};
    if isempty(varargin)

        while true
            [filename, pathname] = uigetfile('*.*', 'Select a File');
            if isequal(filename, 0)
                break;
            end
            fullpath = fullfile(pathname, filename);
            fullPathsCell{end+1} = fullpath;
        end

    else
        [filename, pathname] = uigetfile('*.*', 'Select a File');
        fullpath = fullfile(pathname, filename);
        fullPathsCell{end+1} = fullpath;
    end
    %Check to see that the files are microscopy files and similar filetypes
    lastThreeChars = extractAfter(fullPathsCell{1}, strlength(fullPathsCell{1}) - 3);
    disp("Selected Files: ")
    for i=1:numel(fullPathsCell)
        disp(fullPathsCell{i})
        if lastThreeChars ~= "czi" && lastThreeChars ~="oir" && lastThreeChars ~= "nd2"
            error("Invalid input: Selected files were not microscopy files!") 
        end
        if extractAfter(fullPathsCell{i}, strlength(fullPathsCell{i}) - 3) ~=lastThreeChars
            error("Invalid input: Selected files were not similar microscopy files!")
        end        
    end
end