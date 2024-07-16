function euclidean_3D_dmap=euclidean_distance_map(Ibw_resized)
    euclidean_3D_dmap=zeros(size(Ibw_resized));
    for i = 1:size(Ibw_resized,1)  
        euclidean_3D_dmap(i,:,:)=bwdist(squeeze(Ibw_resized(i,:,:)),"euclidean");
    end
end