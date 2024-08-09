
%This is the function which creates color image out of .oir files
function separate_channels=dataFromOir(path,varargin)
    oirData = bfopen(path);

    % Read the image data and extract the needed dimensions
    imageData = oirData{1, 1};
    time_samples = str2double(extractAfter(oirData{1, 1}{1, 2}, ...
        strlength(oirData{1, 1}{1, 2}) - 2));

    if isnan(time_samples); time_samples=1;end    

    nbr_of_channels=size(oirData{1, 3}{1, 1},2);
    nbr_of_slices=size(imageData,1)/time_samples/nbr_of_channels;
    resol=size(imageData{1,1},1:2);

    %Setting the 3D image data into a tensor 
    image3D = cat(3, imageData{:,1});
    
    %Extracting the color channels from the image and creating a 4D tensor
    %from the image data
    separate_channels=zeros(resol(1),resol(2),nbr_of_slices*time_samples ...
        ,nbr_of_channels);

    for i=1:nbr_of_channels
        separate_channels(:,:,:,i)=image3D(:,:,i:nbr_of_channels:end);
    end
    
    %Prompt if all time_samples are wanted in the file
    %prompt = "Do you want all time samples? (1 for yes/ 0 for no): ";

    if ~isempty(varargin)
        disp('The dimensions of the file(x y time channels): ')
        disp(size(separate_channels))
    else
    
    
        %Prompt where the user can pick the time sample which will be used in volumeViewer
        prompt = "Select the time sample (1 to "+time_samples+"): ";
        EXP = input(prompt);
        if EXP >= 1 && EXP <= time_samples
            disp("Selected time sample: "+EXP);
            separate_channels=separate_channels(:,:,EXP:time_samples:end,:);
        else
            disp("ERROR. The input was not in [1,"+time_samples+"]. Selecting the first time sample by default.");
            separate_channels=separate_channels(:,:,1:time_samples:end,:);
        end
        
        %Asks the user if histogram is wanted
        prompt2="Histogram from the color channels?(1 for yes / 0 for no): ";
        h=input(prompt2);
        if(h==1)
            figure;
            for i=1:nbr_of_channels
                subplot(nbr_of_channels,1,i)
                chn=separate_channels(:,:,:,i);
                histogram(chn(:)) %r
                title("Channel nbr: "+i)
            end
            sgtitle('Histograms for all the channels')
        end
    end

end