%THIS FILE IS WAS ONLY USED TO PRODUCE THE WHITE APICAL SIDE OF THE CELL
%SURFACE


path1='C:\Users\manninem\Documents\phagocytosis\Control_3D_t34min.czi';
path2='C:\Users\manninem\Documents\phagocytosis\Control_3D_t64min.czi';
path3='C:\Users\manninem\Documents\phagocytosis\Control_3D_t94min.czi';
path=[path1;path2;path3];
%path='C:\Users\manninem\Documents\phagocytosis\nd2\20222810_live phago_porchine RPE_sir actin and ATTO488 POS_1 - Denoise_ai.nd2';

%Reads the data from the file
volumes=cell(1,size(path,1));
for i=1:size(path,1)
    disp(path(i,:))
    CziData = bfopen(path(i,:));
    imageData = CziData{1, 1};
    nbr_of_channels=size(CziData{1, 3}{1, 1},2);
    nbr_of_slices=size(imageData,1)/nbr_of_channels;
    resol=size(imageData{1,1},1:2);
    image3D = cat(3, imageData{:,1});
    separateChannels=zeros(resol(1),resol(2),nbr_of_slices ...
        ,nbr_of_channels);

    for j=1:nbr_of_channels
        separateChannels(:,:,:,j)=image3D(:,:,j:nbr_of_channels:end);
    end

    %separateChannels(:,:,:,nbr_of_channels)=separateChannels(:,:,:,nbr_of_channels).*0;
    %size(separateChannels)
    volumes{1,i}=separateChannels(:,:,(nbr_of_slices-87):end,:);
end
error= rmse(volumes{1,1}(:,:,:,2),volumes{1,3}(:,:,:,2),'all');


for i=1:size(volumes,2)
    disp(size(volumes{1,i}))
end

% reshapedImage = reshape(separateChannels, size(separateChannels,1), ...
%     size(separateChannels,2), size(separateChannels,3), size(separateChannels,4));
% grayscaleImage = mean(reshapedImage,4);
% grayscaleImage=imgaussfilt3(grayscaleImage,0.5);

    
%Parhaiten saa pinnan näkymään 200 - 250. Alle 200 ei erotu kunnolla
%notkelmat, mutta myös reijät näkyy! Saisko reikiä kurottua oir kuvissa
%yhistämällä kalvot eri aikasarjoista? JA 


%Extract the isosurface of the reference volume at the specified isovalue.
meshes=cell(1,3);
isovalue =220;  
%figure;
color=["magenta","green", "yellow"];
kanava=input("Which channel?(1, 2): ");
for i=1:3
    solukalvo=volumes{1,i}(:,:,:,kanava);
    %volumeViewer(solukalvo)
    [~,verts] = extractIsosurface(solukalvo,isovalue);
    ptCloud=pointCloud(verts);
    %pcshow(ptCloud.Location,color(i))
    gridstep = 5;
    tic
    ptCloudDownSampled = pcdownsample(ptCloud,"gridAverage",gridstep);
    %ptCloudDownSampled = pcdownsample(ptCloud,"nonuniformGridSample",5000);
    %ptCloudDownSampled =rmoutliers(ptCloudDownSampled.verts);
    toc
    disp("points in the cloud: "+ size(ptCloudDownSampled.Location,1));
    tic
    depth=5;
    mesh = pc2surfacemesh(ptCloudDownSampled,"poisson",depth);
    toc
    meshes{1,i}=mesh;
    %surfaceMeshShow(mesh,Title="Kalvon pinta eristetty, nro: "+i)               %commented out not to see the surface mesh
    
    %pcshow(ptCloud.Location,color(i))
    
    hold on
end
% V=separateChannels(:,:,:,2);
% POS=separateChannels(:,:,:,1);
% 
% [faces,verts] = extractIsosurface(V,isovalue);
% [POSfaces,POSverts] = extractIsosurface(POS,isovalue);
% 
% ptCloud = pointCloud(verts);
% POSptCloud=pointCloud(POSverts);


% figure
% pcshow(ptCloud.Location,'magenta');
% hold on
% pcshow(POSptCloud.Location,'green')
% fontSize = 14;
% cap=sprintf('POS Pötkylä ja kalvo \n \n');
% title(cap,'FontSize',fontSize)
% hold off
gridstep = 10;
figure;
for i= 1:3
    ptCloudDownSampled = pcdownsample(ptCloud,"gridAverage",gridstep);
    depth=5;
    mesh = pc2surfacemesh(ptCloudDownSampled,"poisson",depth);
    surfaceMeshShow(mesh,Title="Kalvon pinta eristetty")
   
    kalvo=pointCloud(double(meshes{1,i}.Vertices));
    pcshow(kalvo.Location,color(i));
    hold on
end
title("RMSE Z=1:95  : "+ error)
hold off

%title("Isovalue: "+isovalue)                                               
% 
% fontSize = 14; % Whatever you want.
% caption = sprintf('POS and the surface \n \n \n');
% title(caption, 'FontSize', fontSize)
% 
% xlabel("X(\mum)")
% ylabel("Y(\mum)")
% zlabel("Z(\mum)")

%grayscaleImage=imgaussfilt3(separateChannels(:,:,:,2),0.5);

