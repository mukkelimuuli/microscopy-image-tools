%A CRITICAL ASSUMPTION IS THAT THE PARTICLE DOES NOT MOVE AND THE CENTER
%STAYS PUT OVER THE TIME SERIES

%Selecting the data file and extracting image data from the file
[fullPathsCell,ltc]=while_file_selection(1);
separateChannels=file_selection(ltc,fullPathsCell{1},1);



%Extracting only the needed channel, as default the channel is 1.

% The third dimension can be changed if only a part of the time series is 
% wanted for the analysis, e.g. POS=separateChannels(:,:,1:20,1); gives you
% the first 20 timepoints.
POS=separateChannels(:,:,:,1);

%Selecting the Region Of Interested from the image
ROI=roi_selection(squeeze(separateChannels(:,:,1)));
ROI(1:2)=round(ROI(1:2));
ROI(3:4)=floor(ROI(3:4));
POS_ROI=POS(ROI(2):ROI(2)+ROI(4),...
    ROI(1):ROI(1)+ROI(3),:);

%Calculating the average image of all of the time points to extract the
%middle part of the POS 



if ltc ~= "tif"
    pixelPhysicalSize = bfGetReader(fullPathsCell{1,1}).getMetadataStore()...
        .getPixelsPhysicalSizeX(0).value();
    pixPerUm=1/(pixelPhysicalSize.doubleValue);
else
    info=imfinfo(fullPathsCell{1,1});
    pixPerUm=info.XResolution;
end
AreaPerPix=(1/pixPerUm)*(1/pixPerUm);
summed_up=uint16(zeros(size(POS_ROI,1:2)));

timepoints=size(POS_ROI,3);
for i= 1:timepoints
    summed_up=summed_up+uint16(POS_ROI(:,:,i));
end
averaged_image=imfill(uint8(summed_up./timepoints));

%Selecting the intensity treshold
intensity_threshold=threshold_slider(averaged_image,...
    "Select a value where only the core is visible");

%Thresholding the averaged image to extract only the center of the POS
%particle which is static in the time series and finding edges of the
%averaged center image
copy=averaged_image;
copy(copy <= intensity_threshold ) = 0;


center=imbinarize(copy);
edges=edge(center,"canny");
%The averaged center image's edge row and cols
[row,col]=find(edges==1);
le=length(row);

%Center point calculation of the center image cp=[y, x]
cp=[round((max(row)+min(row))/2),round((max(col)+min(col))/2)];

%Coordinates and angles note:
%   y-axis = row
%   x-axis = col
%   positive y --> down
%   positive x --> right
%   0-angle towards negative y-axis i.e. up

%ECA stands for edge_coordinate_angle [row,col,angle]
eca=zeros(le,3);
eca(:,1)=row;
eca(:,2)=col;

%Angles into ECA
for i = 1:le
    eca(i,3)=atan2(cp(2)-col(i),cp(1)-row(i))*180/pi;
end

%Sorting into circular order, worth doing if tangents are calculated... 
%from the edges, this was done before realizing that there is a simpler way
s_eca=sortrows(eca,3);

%Linear indexing of the center part to extract the alternating area of
%the particle pulling for later processing.
[center_row,center_column]=find(center==1);
linear_indices = sub2ind(size(averaged_image), center_row, center_column);

%Defining an lambda function for median filtering
myfun = @(x) median(x(:),'omitnan');

%Going through all the time points 
Area=zeros(timepoints,1);
distances=zeros(size(s_eca,1),timepoints);
Outern_A_ratio=zeros(timepoints,1);

%Most of the calculation is done inside this loop!
for i=1:timepoints
    I=squeeze(POS_ROI(:,:,i));

    %7x7 filter window is proven suitable empirically
    %with a specific time series, one can try different sizes if
    %results are not pleasing    v
    fI = imbinarize(nlfilter(I,[7 7],myfun));
    
    %Calculating the area of the alternating part of the POS particle
    A_calc=fI;
    A_calc(linear_indices)=0;
    Area(i)=sum(A_calc(:) == 1)*AreaPerPix;
    Outern_A_ratio(i)=sum(A_calc(:) == 1)/sum(fI(:) == 1);
    
    %The distances of the center and the outer edge of the pulling part of
    %the POS particles
    distances(:,i)=dist_calc(fI,cp,s_eca)./pixPerUm;
end

%%
%If not needed, this section can be commented out, it only shows the steps
%of the algorithm in images for the user to see how it works
f1=figure;
subplot(131,'Parent',f1);
imshow(squeeze(separateChannels(:,:,1)))

subplot(132,'Parent',f1)
imshow(center)

subplot(133,'Parent',f1)
imshow(A_calc)
sgtitle({"Phases of the algorithm: noisy image, extracted center from"+...
    " averaged image and the part of POS"," experiencing the pulling, "+...
    "i.e. the alternating area around the center (from a single time point)"})
%%

f2=figure;
ax1=subplot(3,1,1,'Parent',f2);
stem(ax1,1:timepoints,Area,'filled')
grid(ax1,"minor")

title(ax1,"Alternating area outside of the POS particle center")
xlabel(ax1,"Time as timepoints")
ylabel(ax1,"Area (\mum^2)")
legend_str = sprintf('Mean: %.2f, Std: %.2f, Var: %.2f', ...
    mean(Area), std(Area), var(Area));
legend(ax1, 'show',legend_str);

ax2=subplot(3,1,2,'Parent',f2);

%VAR CAN BE CALCULATED BY REPLACING THE MEAN FUNCTION WITH VAR
mean_distances = mean(distances, 1);

stem(ax2,1:timepoints,mean_distances,'filled')
grid(ax2,"minor")

title(ax2,"The mean distances ("+size(distances,1)+" points each) of "+...
    "the center of the POS edge and the "+...
    "outern edge of the pulling part of the particle")
xlabel(ax2,"Time as timepoints")
ylabel(ax2,"Distance (\mum)")
legend_str2 = sprintf('Mean: %.2f, Std: %.2f, Var: %.2f',...
    mean(mean_distances),std(mean_distances),var(mean_distances));
legend(ax2, 'show',legend_str2);

ax3=subplot(3,1,3,'Parent',f2);
stem(ax3,1:timepoints,Outern_A_ratio,'filled')
grid(ax3,"minor")

title(ax3,"The ratio between the alternating area and the whole area")
xlabel(ax3,"Time as timepoints")
ylabel(ax3,"The ratio")
legend_str3 = sprintf('Mean: %.2f, Std: %.2f, Var: %.2f',...
    mean(Outern_A_ratio),std(Outern_A_ratio),var(Outern_A_ratio));
legend(ax3, 'show',legend_str3)

%The folder where this file runs is chosen to be the directory for saving
%the output files. One can alternate the folder name e.g. if multiple runs 
%are needed.
[folder, ~, ~] = fileparts(which('POS_particle_pulling_statistics.m'));
foldername='POS_particle_pulling_results';
mkdir(folder,foldername);

%Saving the plots into an image
f1.WindowState='fullscreen';
f2.WindowState='fullscreen';
saveas(f1,strcat(folder,'\',foldername,'\steps.png'))
saveas(f2,strcat(folder,'\',foldername,'\data.png'))
f1.WindowState='normal';
f2.WindowState='normal';

% Create the alphabet for sheet indexing
A = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

%Writing the data into an .xlsx file
fname = strcat(folder, '\', foldername, '\data_from_subplots.xlsx');
delete(fname)

% Write the data into .xls file
writematrix("The alternating area outside of the POS particle center"+...
    "(one column per time series)", fname);
writematrix(Area,fname,'Range', strcat(A(1), int2str(2)))


writematrix("The mean distances of the POS center edge and the outern"+...
    " edge of the pulling part of the particle (the angle of "+...
    "calculation is towards the center point of the center)", fname,...
    'Range', strcat(A(1), int2str(3+timepoints)));
writematrix(mean_distances',fname,'Range', strcat(A(1), ...
    int2str(4+timepoints)))

writematrix("The ratio between alternating part of the POS particle"+...
    " and the center part of the particle", fname,...
    'Range', strcat(A(1), int2str(5+timepoints*2)));
writematrix(Outern_A_ratio,fname,'Range', strcat(A(1), ...
    int2str(6+timepoints*2)))


