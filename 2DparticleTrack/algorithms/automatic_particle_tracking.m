%This function is a function used by twoDparticleTracking.m file. It does 
%the particle tracking and plots data and saves them into a new folder in
%plots and sheet data form. The folder's name is particle_tracking_files
%and it will be saved in the same folder as this file.


function automatic_particle_tracking(maskedImage,chosen_series,c, ...
    intensity_threshold,pixPerUm)

%Searching for pixels which represent the segmented particle and uses its
%center point as the center of the window defined later. The variable le 
%is just the length of the time series for later use.
[x,y]=find(maskedImage~=0);
pt=[round(mean(x)),round(mean(y))];
le=size(chosen_series,3);

%max_linking_distance: tells the max euclidean distance which the particles
%can travel between the time points!!

max_linking_distance =10; 

%Taking a smaller window series to track moving points for clearer results
% and thresholding the windows
window_series=chosen_series(pt(1)-c:pt(1)+c,pt(2)-c:pt(2)+c,:);
window_series(window_series <= intensity_threshold ) = 0;

%Clustering all the points in the window for every time point
points_index_centers={};
cluster_nbr={};
for i=1:le
    points_index_centers{end+1} =dbscan_clustering(...
        imbinarize(squeeze(window_series(:,:,i))),i,false);
    
    cluster_nbr{end+1}=unique(points_index_centers{i}(:,3));
    if cluster_nbr{i}==-1
        error("Time point "+i+" clustering doesn't provide proper" + ...
            " clusters since the particle is too small, adjust the " + ...
            "clustering parameters or select different time points/" + ...
            "section of the image. One can check the clustering process" + ...
            " by changing row 32 parameter false --> true.")
    end
end

%Searching for the centers of the clustered points by using the
%cluster_center_points algorithm.
centers=[];
sizes={};
for i=1:le
    [centers{end+1},sizes{end+1}]=cluster_center_points(...
        points_index_centers{i},cluster_nbr{i},pixPerUm);    
end

%By uncommenting rows 56-61, one can get all the windows which 
%the calculations are done with shown in a single subwplot image.
% 
% figure;
% p=ceil(sqrt(le));
% for i=1:le
%     subplot(p,p,i)
%     imshow(squeeze(window_series(:,:,i)))
% end


%Using the simple tracking algorithm to link the centers of the clustered
%particle data.
max_gap_closing = Inf;
debug = true;
tic
[tracks,adjacency_tracks,~]=simpletracker(centers,...
    'MaxLinkingDistance', max_linking_distance, ...
    'MaxGapClosing', max_gap_closing, ...
    'Debug', debug);
toc

%The plotting of the tracked points and
n_tracks = numel(tracks);
all_points = vertcat(centers{:});
tracing_points={};

%Creating tracing_points cell to easy access for the timepoints
for i=1:le
    for i_track=1:n_tracks
        if length(adjacency_tracks{i_track})>=i
            tracing_points{i,i_track}=all_points(...
                adjacency_tracks{i_track}(i),:);
        end
    end
end    


%Creating the gif file for the tracing of the particles by drawing the
%tracked lines into the original picture by using bresenham algorithm and
%combine_tracing_and_image algorithm.
tracing=zeros(size(window_series,1:2));
f=figure;
hAx = axes(f);
I=combine_tracing_and_image(chosen_series(:,:,1),...
    zeros(size(chosen_series(:,:,1))),1);
setparams(I,0);





%The folder where this file runs is chosen to be the directory for saving
%the output files. One can alternate the folder name e.g. if multiple runs 
%are needed.
[folder, ~, ~] = fileparts(which('automatic_particle_tracking.m'));
foldername='particle_tracking_files';
mkdir(folder,foldername);

gif(strcat(folder,'\',foldername,'\window_tracing.gif'),'DelayTime',1/2,'LoopCount',10)
for i=1:le-1
    for j=1:n_tracks
        if ~isempty(tracing_points{i+1,j})
            [x,y]= bresenham_2d(tracing_points{i,j}(1),...
                tracing_points{i,j}(2),...
                tracing_points{i+1,j}(1),tracing_points{i+1,j}(2));
        end
        for k = 1:length(x);tracing(x(k), y(k))= j;end
    end
    tracing_window = combine_tracing_and_image(window_series(:, :, i+1),...
        tracing,n_tracks);
    cImg=combine_tracing_and_image(chosen_series(:,:,i+1),zeros(...
        size(chosen_series(:,:,i+1))),n_tracks);
    cImg(cImg <=40 ) = 0;
    cImg(pt(1)-c:pt(1)+c,pt(2)-c:pt(2)+c,:)=tracing_window;
    cImg=setparams(cImg,i);
    %imshow(cImg,'parent',hAx);
    gif
end



%Saving the last image of the gif
imwrite(cImg,folder+"\"+foldername+"\last_image_of_gif.png")

%Showing the resulting gif
web(strcat(folder,'\',foldername,'\','window_tracing.gif'))

%Calculating the distances between the particles in adjacent timepoints and
%subplotting the travelled distances of the particles and their sizes into
%the same figure.
distances={};
angles={};

f=figure;
ax1=subplot(311);
ax2=subplot(312);
colors=hsv(size(adjacency_tracks,1));
for i=1:size(tracing_points,2)
    for j=1:size(tracing_points,1)-1
        if ~isempty(tracing_points{j+1,i})
            distances{j,i}=norm(tracing_points{j+1,i}-...
                tracing_points{j,i})/pixPerUm;
            angles{j,i}=atan2((tracing_points{j+1,i}(2)-...
                tracing_points{j,i}(2)),(tracing_points{j+1,i}(1)-...
                tracing_points{j,i}(1))).*180/pi;
        end
    end
    if size(distances,2)>=i
        if length(cell2mat(distances(:,i))')>2
            plot(ax1,1:length(cell2mat(distances(:,i))'),cell2mat(...
                distances(:,i))','-.o','Color',colors(i,:),...
                'MarkerFaceColor',colors(i,:),...
                'MarkerEdgeColor',colors(i,:));
            hold(ax1, 'on');
            
            plot(ax2,1:length(cell2mat(angles(:,i))'),cell2mat(...
                angles(:,i))','-.o','Color',colors(i,:),...
                'MarkerFaceColor',colors(i,:),...
                'MarkerEdgeColor',colors(i,:));
            hold(ax2, 'on');
        end
    end
end
title(ax1,"The distances traveled by particles over adjacent timepoints")
ylabel(ax1,"The euclidean distance (\mum)")
xlabel(ax1,"The adjacent timepoints")

title(ax2,"The angles between adjacent particles over timepoints" + ...
    "(0 being towards positive x-axis and 180 towards negative x-axis)")
ylabel(ax2,"The angle (degrees)")
xlabel(ax2,"The adjacent timepoints")

grid(ax1,'minor')
grid(ax2,'minor')
legend(ax1, 'show');
legend(ax2, 'show');

%Defining the structure dimensions by the longest array in the sizes cell
row_lengths = cellfun(@(x) size(x, 1), sizes);
max_row_length = max(row_lengths);

%Converting the data from sizes differently for easier plotting
sizes_vectors=cell(1,max_row_length);
for i=1:size(sizes,2)
    for j=1:size(sizes{i})
        sizes_vectors{j}={cat(1,cell2mat(sizes_vectors{1,j}),sizes{i}(j))};
    end
end

%Plotting the sizes of the particles into the same subplot as the distances
ax3=subplot(313);
for i=1:length(sizes_vectors)
     plot(ax3,1:length(cell2mat(sizes_vectors{1,i})),cell2mat(...
         sizes_vectors{1,i}),'-.o','Color',colors(i,:),'MarkerFaceColor'...
         ,colors(i,:),'MarkerEdgeColor',colors(i,:));
     hold(ax3, 'on');
    
end
title("The sizes of the particles in each time point")
grid(ax3,'minor');
xlabel("Time points")
ylabel("Particle size (\mum^2)")
legend(ax3, 'show');

%Saving the subplot as an image, setting it temporarily to fullscreen to
%see the plots adn the texts better
% set(gcf, 'Position', get(0, 'Screensize'));
f.WindowState='fullscreen';
saveas(gcf,strcat(folder,'\',foldername,'\data_subplots.png'))
f.WindowState='normal';

% Create the alphabet for sheet indexing
A='ABCDEFGHIJKLMNOPQRSTUVWXYZ'; 

%Creates a folder to the same directory as this file, outputs the data
%there and locates the cells correctly into the file.
fname=strcat(folder,'\',foldername,'\data_from_subplots.xls');

writematrix("The distances (micrometers), where each row is a different time point," + ...
    " and each column is data from one particle ",fname)
inds=size(distances);
indexes1=strcat(A(1),"2:",A(inds(2)),int2str(inds(1)+1));
writecell(distances,fname,'Range',indexes1)
writematrix("The angles (degrees), where each row is a different time point," + ...
    " and each column is data from one particle ",fname,'Range',...
    strcat(A(1),int2str(inds(1)+3)));
beg2=inds(1)+4;
end2=beg2+inds(1);
indexes2=strcat(A(1),int2str(beg2),':',A(inds(2)),int2str(end2));
writecell(angles,fname,'Range',indexes2);
writematrix("The sizes (square micrometers) , where one row represents one particle and" + ...
    " each column indicates a time point" ...
    ,fname,'Range',strcat(A(1),int2str(end2+1)));

for i=1:size(sizes_vectors,2)
    writecell(sizes_vectors{1,i},fname,'Range',strcat('A',int2str(end2+1+i)))
end

disp("Results are ready in the "+ foldername+" folder.")

    %Sets the params for the gif image scalbar and serial number
    function I=setparams(I,i)
        I=insertText(I,[450,20],i+1,FontSize=20, ...
            BoxOpacity=0.0,TextColor="r");        
        imshow(I, 'Parent',hAx)
        
        %Params for the scalebar
        scalebarLength = 5;  % scalebar will be 5um
        unit = sprintf('%s%s','\mu','m'); % micrometer
        hScalebar = scalebar(hAx, 'x', scalebarLength, unit,...
            'Location', 'southeast','ConversionFactor', pixPerUm);
        hScalebar.Color = 'r';
        hScalebar.LineWidth=3;
        hScalebar.FontSize=16;
        hScalebar.FontName='comic sans';
       
    end
end


