%Extracts the needed data from a .czi microscopy image file
%to create a 

function separateChannels=dataFromCzi(path,varargin)
    
        
    CziData = bfopen(path);
    
    % Read the image data and the needed dimensions
    imageData = CziData{1, 1};
    nbr_of_channels=size(CziData{1, 3}{1, 1},2);
    nbr_of_slices=size(imageData,1)/nbr_of_channels;
    resol=size(imageData{1,1},1:2);
    
    %Setting the first into 3D image data into a tensor and separate the 
    % channels into a 4D tensor 
    image3D = cat(3, imageData{:,1});
    separateChannels=zeros(resol(1),resol(2),nbr_of_slices ...
        ,nbr_of_channels);
    
    for i=1:nbr_of_channels
        separateChannels(:,:,:,i)=image3D(:,:,i:nbr_of_channels:end);
    end
    
    %separateChannels(:,:,:,nbr_of_channels)=separateChannels(:,:,:,nbr_of_channels).*0;
    if ~isempty(varargin)
        disp('The dimensions of the file(x y time channels): ')
        disp(size(separateChannels))
    end
    %Asks the user if histogram is wanted
    %prompt2="Histogram from the color channels?(1 for yes / 0 for no): ";
    %h=input(prompt2);
    h=0;
    if(h==1)
        figure;
        for i=1:nbr_of_channels
            subplot(nbr_of_channels,1,i)
            histogram(mean(separateChannels(:,:,:,i))) %r
            title("Channel nbr: "+i)
        end
        sgtitle('Histograms for all the channels')
    end

end