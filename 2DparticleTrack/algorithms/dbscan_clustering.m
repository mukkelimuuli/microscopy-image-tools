function points_index_centers=dbscan_clustering(binarized,i,plots)



%tee 2D implementaatio samalla tavalla!
if numel(size(binarized))==3

    %Find point coordinates from the 3D array
    [x,y,z,~]=find3(binarized==1);
    
    %Calculate the dbscan algorithm from the data and plot the scatterplot
                            %epsilon, min points
    [idx,centers] = dbscan([x,y,z],10,5,'Distance','squaredeuclidean');

    % MITEN SAIS TEHTYÄ THRESHOLDIN %MINKÄ THRESHOLDIN?
    if plots == true
        figure;
        scatter3(x,y,z,50,idx,'filled')
        title("Scatter plot of the clustered data (-1 = outlier), file nbr: "+i)
        colorbar
        axis([0 512 0 512 0 95])
        hold off
        
    end
    points_index_centers=[x,y,z,idx,centers];
else
    eps=5;
    minpts=20;
    [x,y]=find(binarized==1);
    [idx,centers]=dbscan([x,y],eps,minpts,"Distance","squaredeuclidean");

    
    %comment off if clusters wanted to be seen
    if plots ==true
        figure;
        scatter(y,x,50,idx,'filled')
        title("Scatter plot of the clustered data (-1 = outlier), file nbr: "+i+", epsilon: "+eps+", minpts: "+minpts)
        set(gca, 'Ydir','reverse')
        hold off
        colorbar
    end
    points_index_centers=[x,y,idx,centers];
    
    

    %MITEN SAA KÄÄNNETTYÄ 90 ASTETTA??
end


