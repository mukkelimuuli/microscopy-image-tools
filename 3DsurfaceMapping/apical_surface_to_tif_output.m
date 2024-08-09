%This file creates tif files from the apical surface of the microscopy
%images. 

%First the file is read and the essential information from it is extracted
[fullPathsCell,ltc]=while_file_selection(1);
separateChannels=file_selection(ltc,fullPathsCell{1},1);

%Channel of the surface
CHN=2;


% if lastThreeChars == "czi" || lastThreeChars =="oir" || lastThreeChars == "nd2"
%     if lastThreeChars =="czi"
%         separateChannels=dataFromCzi(fullpath);
%     elseif lastThreeChars =="oir"
%         separateChannels=dataFromOir(fullpath,0);
%         highest_intensity=max(max(max(separateChannels(:,:,:,CHN))));      
%         for i  = 1: size(separateChannels(:,:,:,CHN),3)
%             plane=separateChannels(:,:,i,CHN);
% 
%             %Trying to scale the .oir file intensities similar to .czi
%             separateChannels(:,:,i,CHN) = imadjust(plane)*255;  
%         end
% 
%     else
%         separateChannels=dataFromNd2(fullpath);
%     end
% end

%%

%One might need to change the isovalue. One can try different values and
%the histogram can give some information what it should be. At least for 
%.czi images 220 is a good value.

answer=input("Do you want to choose the threshold yourself?(1 for yes/0 for no): ");

if answer==1
    %midpoint of y-axis
    midpoint=round(size(separateChannels,1)/2);

    chosen_threshold=threshold_slider(squeeze(separateChannels(...
        :,midpoint,:,CHN)),"Select the threshold so that noise is " + ...
        "mitigated but the edge of the cell surface is visible");
    if chosen_threshold==0
        error("Error: Threshold was not chosen!")
    end
    isovalue=chosen_threshold;
else
    if ltc=="czi"
        isovalue=220;        %?, not tested
    elseif ltc=="oir"
        isovalue=1200;
    else
        isovalue=60;         %?, not tested
    end
end


%The isosurface is extracted from the data abd it is then mapped into voxel
%data again.

[~,verts] = extractIsosurface(squeeze(separateChannels(:,:,:,CHN)), isovalue);


Iheight = nan*zeros(size(separateChannels,1),size(separateChannels,2));
for i=1:size(verts,1)
    first_index=round(verts(i,1));
    second_index=round(verts(i,2));
    %Change due to .oir files produce 0 and it cannot be indexed
 
    if  first_index < 1;first_index=1;end
    if second_index <1;second_index=1;end
    Iheight(first_index,second_index)= round(verts(i,3));
end

figure;
subplot(121);surf(Iheight,'LineStyle','none')
set(gca,'View',[0 90]);

% Define surface smoothness: 
gridstep =30;

%Magic (filtering)
myfun = @(x) min(x(:));
myfun2 = @(x) mean(x(:),'omitnan');
I2 = nlfilter(Iheight,[gridstep gridstep],myfun);
I2 = nlfilter(I2,[gridstep gridstep],myfun2);

%Plotting of the mapping process for user to check it seems good enough.
subplot(122);surf(I2,'LineStyle','none')
sgtitle("Mapping of the 3D surface on the apical side of the volume image")
set(gca,'View',[0 90]);

% Convert to BW binary image:
Ibw = 0*separateChannels(:,:,:,2);
for i = 1:size(I2,1)
    for j=1:size(I2,2)
        if ~isnan(I2(i,j))
            Ibw(i,j,round(I2(i,j))+1)=1; % set pixel as surface
        else
            Ibw(i,j,:)=0;       % no information
        end
    end
end

%The edges from filtering removed and the surface interpolated
Ibw_resized= imresize3(Ibw(gridstep:(size(Ibw,1)-gridstep), ...
    gridstep:(size(Ibw,2)-gridstep),:), ...
    [size(Ibw,1),size(Ibw,2),size(Ibw,3)],'method',"linear");

% Create a 3D structuring element and dilate the image to two voxel
se = strel('cube', 2); 
dilated_volume = imdilate(Ibw_resized, se);  
volumeViewer(separateChannels(:,:,:,1)+separateChannels(:,:,:,2))
volumeViewer(dilated_volume)

value=input("Do you want a 3D euclidean distance map as well? (1 for yes, 0 for no): ");

%Creating a folder for the output images
[folder, ~, ~] = fileparts(which('apical_surface_to_tif_output.m'));
foldername='surface_images';
mkdir(folder,foldername);

%Options for tif image saving
options.overwrite = true;
options.compress = 'lzw';
options.jpegquality = 30.0;


if value==1
    %Creating euclidean distance map
    edm=euclidean_distance_map(Ibw_resized);
    
    %And plotting the z-sliced Euclidean distance map
    figure;
    imagesc3D(edm)
   
    %saving edm as tiff
    saveastiff(uint8(edm), strcat(folder,'\',foldername,'\euclidean_distance_map3d.tif'), options);
end

%should permute +90 around z-axis and +90 around x-axis
dilated_volume=permute(dilated_volume,[2,1,3]);
dilated_volume=permute(dilated_volume, [1, 3, 2]);

%saving apical surface as tiff
saveastiff(dilated_volume, strcat(folder,'\',foldername,'\volume_image_of_apical_surface.tif'), options);
