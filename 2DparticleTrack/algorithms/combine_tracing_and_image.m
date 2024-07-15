function colorImg = combine_tracing_and_image(image, tracing, nbr_of_colors)
    
    % Scale the 'image' image to 0-255 intensities
    dImage = double(image);
    minVal = min(dImage(:));
    maxVal = max(dImage(:));
    scaledImg = (dImage - minVal) * (255 / (maxVal - minVal));
    
    % Convert back to uint8
    scaledImg = uint8(scaledImg);
    
    % Create an RGB image from the scaled grayscale particles image
    colorImg = cat(3, scaledImg, scaledImg, scaledImg);
    
    % Overlay the path as red on the RGB image
    colorImg(:,:,1) = uint8(tracing) * 255 + (1 - uint8(tracing)) .* colorImg(:,:,1);
    
    % Create a colormap (e.g., hsv) with nbr_of_colors
    cmap = hsv(nbr_of_colors);
    
    % Assign colors based on the tracing values
    for i = 1:nbr_of_colors
        [x, y] = find(tracing == i);
        if ~isempty(x)
            for k = 1:numel(x)
                colorImg(x(k), y(k), 1) = uint8(cmap(i, 1) * 255);
                colorImg(x(k), y(k), 2) = uint8(cmap(i, 2) * 255);
                colorImg(x(k), y(k), 3) = uint8(cmap(i, 3) * 255);
            end
        end
    end
end


