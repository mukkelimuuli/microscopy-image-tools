%With this file, one can perform object tracking of 3D  microscopy images.

%The chosen timepoints need to be in a chronological order!

% A while loop of asking the user to select files until cancel or exit
% is pressed to continue with the file

[fullPathsCell,ltc]=while_file_selection();
cellsize=numel(fullPathsCell);
possit=cell(1,cellsize);

prompt="Give the number of the channel where the particles are: ";
chn=input(prompt);

%Inside the for loop, the POS particles are extracted from the channels
for i=1:numel(fullPathsCell)
    separateChannels=file_selection(ltc,fullPathsCell{i});
    possit{1,i}=separateChannels(:,:,:,chn); 
end

%Intensity threshold for POS particle extraction
answer=input("Do you want to choose the threshold yourself?(1 for yes/0 for no): ");

if answer==1
    mid_slice_nbr=round(size(possit{1,1},3)/2);
    chosen_threshold=threshold_slider(squeeze(possit{1,1}(:,:,mid_slice_nbr)));
    if chosen_threshold==0
        error("Error: Threshold was not chosen!")
    end
    intensity_threshold=chosen_threshold;

else
    if ltc=="czi"
        intensity_threshold=220;        %?, not tested
    elseif ltc=="oir"
        intensity_threshold=550;
    else
        intensity_threshold=60;         %?, not tested
    end
end

thresholded=cell(1,cellsize);
binarized=cell(1,cellsize);
points_index_centers=cell(1,cellsize);
cluster_nbr=cell(1,cellsize);

%The lowest z-dimension needs to be found from the 
%dataset to determine the common size for all data in the z-dimension
%in order to align the voxel images
z_sizes = cellfun(@(x) size(x, 3), possit);
lowest_z = min(z_sizes)-1;

%Updating the possit with uniform sizes of z-stacks
for i=1:cellsize
    nbrchn=size(possit{1,i},3);
    possit{1,i}=possit{1,i}(:,:,((nbrchn-lowest_z):end),1); 
end

%Possit are thresholded and binarized and finally the binarized particle data 
%is clustered with dbscan clustering. Then the center locations of the
%clusters are calculated for each file for further point tracking!
for i=1:cellsize
    thresholded=possit{1,i};
    thresholded(thresholded <= intensity_threshold) = 0;
    binarized{1,i}=imbinarize(thresholded);
    points_index_centers{1,i}=dbscan_clustering(binarized{1,i},i,true);    %change false --> true if clustering needs to be seen
    cluster_nbr{1,i}=unique(points_index_centers{1,i}(:,4));
end
volumeViewer(possit{1,1})

%%
%Centers of the clusters, the sizes of the clusters and their travelled 
%distances are calculated. 
centers=cell(1,cellsize);
sizes=cell(1,cellsize);
distances=cell(1,cellsize-1);
for i=1:cellsize
    [centers{1,i},sizes{1,i}]=cluster_center_points(points_index_centers{1,i},cluster_nbr{1,i});
    if i>1
       
        %TODO: Needs to be upscaled if many distances and centers in the
        %same time point
        
        distances{i-1}=norm(centers{i-1}(1,:)-centers{i}(1,:));
    end
end


%Plot the center points
figure;
voxels=zeros(1,numel(centers));
for i=1:cellsize
    scatter3(centers{1,i}(:,1),centers{1,i}(:,2)...
        ,centers{1,i}(:,3),'filled')
    hold on
end
title("The center points of the different clusters from each time points " + ...
    "plotted into the same figure")
legend
hold off


%Stem plots for the size progression of between the time points and the 
%distances travelled by POS particles.

%TODO: Needs to be upscaled into a for loop where all are drawn separately
figure;
subplot(121)
stem(1:numel(centers),cell2mat(sizes),'filled')
grid minor
xlabel("Time (nbr of image)")
ylabel("Number of voxels in the particle")
title("Size of the large POS particle")
xlim([0 numel(centers)+1])
ylim([0 max(cell2mat(sizes))*1.1])

subplot(122)
stem(1:numel(centers)-1,cell2mat(distances),'r','filled')
grid minor
xlabel("Adjacent timepoints")
ylabel("Distance (euclidean)")
title("Movement of the particles over adjacent timepoints")
xlim([0 numel(centers)])
ylim([0 max(cell2mat(distances))*1.1])

%Next up the tracking algorithm, uses several files to do the tracking

%Simpletracker used for the track plotting(needed when more than 1 points
%to track in an image).
max_linking_distance =30;
max_gap_closing = Inf;
debug = true;


tic
[tracks,adjacency_tracks,A]=simpletracker(centers,...
    'MaxLinkingDistance', max_linking_distance, ...
    'MaxGapClosing', max_gap_closing, ...
    'Debug', debug);
toc


%TODO: check how it works with different data! Also some segmentation tool
%wouldn't hurt. Segmentation could be done as a slice of the 3D image using 
%the same tools as 2Dparticle tracking uses, i.e. the ROI selection window.

%This way the area and therefore the number of followed particles would be
%smaller! Also computationally


%The plotting of the tracked points and
n_tracks = numel(size(tracks,2));
colors = hsv(n_tracks);
all_points = vertcat(centers{:});
% figure;
for i_track = 1 : n_tracks
   
    % We use the adjacency tracks to retrieve the points coordinates. It
    % saves us a loop.
    
%     track_nbr = adjacency_tracks{i_track};
    
    %track_points = all_points(track_nbr, :);
    bres_lines=zeros(size(thresholded));                                    %Should it be brought out of the loop if upscaled?
    
    %HOW TO IMPLEMENT IF MANY PARTICLES IN AN IMAGE?
    for i=1:size(adjacency_tracks,1)-1
        [x,y,z]=bresenham_line3d(all_points(i,:),all_points(i+1,:));
        for j = 1:length(x)
            bres_lines(x(j), y(j), z(j)) = 10000;
        end        
    end
%     plot3(track_points(:,1),track_points(:,2),track_points(:,3),'-.','Marker',"hexagram",'Color',colors(i_track,:))
%     hold on
%     title("The movement of the large particle over timepoints")
%     grid minor
end

%pos=sum(possit{:});
%volumeViewer(possit{1,1});

pos=zeros([size(possit{1,1}),numel(possit)]);

for i=1:numel(possit);pos(:,:,:,i)=possit{1,i};end      %pos 4D matriisiin
MIP = squeeze(max(pos, [], 4));



%LET'S DRAW THEM ALL INTO A POINTCLOUD
[~,POSvert3] =extractIsosurface(possit{1,cellsize},220);

%needed to run for getting the cell surface for the plot
pampam
[~,BRESvert]=extractIsosurface(bres_lines,100);

% POSptCloud1=pointCloud(POSvert1);
% POSptCloud2=pointCloud(POSvert2);
POSptCloud3=pointCloud(POSvert3);
BRESptCloud=pointCloud(BRESvert);

figure;

colors = hsv(size(path,1));
pcshow(BRESptCloud.Location,colors(1,:),'MarkerSize',20)
hold on
%pcshow(POSptCloud1.Location,colors(2,:))
%pcshow(POSptCloud2.Location,colors(3,:))
pcshow(POSptCloud3.Location,colors(2,:))

pcshow(kalvo.Location,'white','MarkerSize',50)

%%

%https://se.mathworks.com/matlabcentral/answers/417066-how-to-get-the-intensity-values-data-stored-that-is-stored-in-the-voxels-3d-image-at-the-certain
%tilavuuslaskenta pikseleinä!



%Step1: img registration jos tarvii?
%[optimizer,metric] = imregconfig("monomodal");
%optimizer = registration.optimizer.RegularStepGradientDescent;
%metric = registration.metric.MeanSquares;
%registeredImage=imregister(thresholded2,thresholded1,'rigid',optimizer,metric);




