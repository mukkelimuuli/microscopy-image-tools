%Run each section by selecting it by clicking somewhere in the code and 
% press CTRL+ENTER. You can see the left bar as blue when the section is 
% selected. When it's run, run the next one similarly. 

%When the segmentation is done, there is no need to run the first section
%again since the variables are saved in the workspace you can see on the
%right side of this window in "Workspace".

%Reading the file and separating the needed info from it
[fullPathsCell,ltc]=while_file_selection(1);
separateChannels=file_selection(ltc,fullPathsCell{1},1);


%number of the channel which in the particles are
channel=2;

if ltc ~="tif"
    %Read the scale info from the file
    pixelPhysicalSize = bfGetReader(fullPathsCell{1}).getMetadataStore()...
        .getPixelsPhysicalSizeX(0).value();
    pixPerUm=1/(pixelPhysicalSize.doubleValue);
    
    %Extracting only the second channel as defined before. If the particles
    %which need tracking are on some else channel, one needs to change the 
    %number accordingly (2 as default).                        

    series=squeeze(separateChannels(:,:,:,channel));
else
    series=separateChannels(:,:,channel:3:end);                      %      <-- assumption of 3 channels
    info=imfinfo(fullPathsCell{1,1});
    pixPerUm=info.XResolution;
end
%Time series (in 27-35 as default), where the particle tracking is done
%from the selected file, this needs to be changed based on e.g.
%observations made using imageJ on the wanted part of the time series.

%                      changeable 
%                          |
%                          |
%                          v
chosen_series=series(:,:,27:50);

%%
%Going through all the selected images from the series and thresholding
%out intensities under the selected limit(1200 by default) for better
%segmentation. For loop is used for segmentation if the user wants manual
%segmentation e.g. if the automatic version oesn't provide accurate data.
%In the manual case the for loop goes through the images in a reverse order
%so that after all windows are opened the first segmentation tool window is 
%the first image of the series.

%NOTICE: If automatic version is used, the variable name must be
%"maskedImage", otherwise the particle tracking doesn't work since the
%parameter which is going into the automatic_particle tracking function is
%named as such.


%intensity_threshold: the threshold which is used in intensity
%thresholding the image to provide the best data for further processing.
%One should try different values if the image doesn't look good in the
%segmentation window.


answer=input("Do you want to choose the threshold yourself?(1 for yes/0 for no): ");

if answer==1
    chosen_threshold=threshold_slider(squeeze(chosen_series(:,:,end)),...
        "Choose threshold with the slider and press save");
    if chosen_threshold==0
        error("Error: Threshold was not chosen!")
    end
    intensity_threshold=chosen_threshold;

else
    if ltc=="czi"
        intensity_threshold=200;        %?, not tested
    elseif ltc=="oir"
        intensity_threshold=1200;
    else
        intensity_threshold=60;         %?, not tested
    end
end

%Morpheus decision on automatic or manual
choice=myGUI;


if choice ==-1
    error("Error: You must give Morpheus an answer..")

%AUTOMATIC!!
elseif choice==0
    %NOTICE:  
    %The algorithm assumes that the number of
    %tracked particles is constant so the color coding screws up if the
    %number of particles changes. However the data is written correctly and
    %the figures are using correctly data from different amount of
    %particles in the image series.
    automatic_particle_tracking(chosen_series,...
        intensity_threshold,pixPerUm)

%MANUAL!!    
else
    %MANUAL TRACKING, every image needs to be segmented and based on the
    %the segmentations the program calculates the same values. All the
    %segmentations need to be named as BW<nbr> and maskedImage<nbr>
    %where the nbr is a number which image is being segmented the first
    %being 1 etc.

    for i=flip(1:size(chosen_series,3))
        liike=squeeze(chosen_series(:,:,i));
        liike(liike <= intensity_threshold ) = 0;
        imageSegmenter(rescale(liike, 0, 1));
    end
    
    while true
        myvars=who;
        if ~isempty(myvars(startsWith(myvars, strcat('BW',...
                int2str(size(chosen_series,3))))))
            break;
        end
        pause(1);
    end
    disp("it's over")
    %Searches the variables and takes into account variables which have "BW"
    %in their name.
    myvars=who;
    bw_vars = myvars(startsWith(myvars, 'BW'));
    lkm_BW=size(bw_vars,1);

    %Goes through the segmented images and calculates the mid point for the
    %segmented area for tracking and tracks the movement of the center
    %points.
    midpoint=cell(1,lkm_BW);
    for i=1:size(bw_vars)
        var=eval(bw_vars{i});
        [x,y]=find(var==1);
        pt=[round(mean(x)),round(mean(y))];
        midpoint{1,i}=pt;
    end


    %Simpletracker algorithm calculates the connection of the given points and
    %links them together. It uses hungarian linking algorithm.
    [tracks,adjacency_tracks]=simpletracker(midpoint);
    
    %The movement is being drawn 
    n_tracks = numel(tracks);
    colors = hsv(n_tracks);
    all_points = vertcat(midpoint{:});
    
    %The tracked points are being drawn into an image
    figure;
    for i_track = 1 : n_tracks    
        track = adjacency_tracks{i_track};
        track_points = all_points(track, :);
        plot(track_points(:,1),track_points(:, 2), 'Color', colors(i_track, :))   
        title("Route of the particle")
        grid minor
    end
    
    %The gif is being made and the particle route is now drawn into the
    %original pictures.
    tracing=zeros(size(liike));
    angles=[];
    gif('tracing_particle.gif','DelayTime',1/2,'LoopCount',10)
    for i=1:size(track_points,1)-1                          
        [x,y]=bresenham_2d(track_points(i,1),track_points(i,2), ... 
            track_points(i+1,1),track_points(i+1,2));
        for k=1:size(x,1)
            tracing(x(k),y(k))=1;
        end
        og_img=squeeze(chosen_series(:,:,i+1));
        og_img(og_img <= intensity_threshold ) = 0;
        
        %Drawing the tracing tail to every image and making a gif
        cImg=combine_tracing_and_image(og_img,tracing,1);
        imshow(cImg)
        gif
        angles(end+1)=atan2((all_points(i+1,2)-all_points(i,2)),...
            (all_points(i+1,1)-all_points(i,1)));
    
    end
    web('tracing_particle.gif')
    
    figure;
    stem(1:(size(track_points)-1),(180/pi.*angles),'filled')
    grid minor
    title("The angles of adjacent particle locations as a function of timepoints")
    xlabel("Adjacent timepoints")
    ylabel("The angle in degrees")
end


