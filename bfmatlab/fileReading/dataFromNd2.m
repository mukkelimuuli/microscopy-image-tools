function separateChannels=dataFromNd2(path)
    
    %Reads the data from the file and extracts needed dimensions
    nd2_data= bfopen(path);
    imageData=nd2_data{1,1};
    resol=size(imageData{1,1},1:2);
    nbr_of_channels = str2double(imageData{1, 2}(end));
    nbr_of_slices=size(imageData,1)/nbr_of_channels;
    
    
    image3D=cat(3, imageData{:,1});
    
    separateChannels=zeros(resol(1),resol(2),nbr_of_slices ...
        ,nbr_of_channels);
    
    for i=1:nbr_of_channels
        separateChannels(:,:,:,i)=image3D(:,:,i:nbr_of_channels:end);
    end
    
    
    %Asks the user if histogram is wanted
    prompt2="Do you want to see the histogram from the " + ...
        "color channels?(1 for yes / 0 for no): ";
    h=input(prompt2);
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