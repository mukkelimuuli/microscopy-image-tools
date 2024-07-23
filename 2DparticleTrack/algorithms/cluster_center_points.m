function [pts_cell,sizes]=cluster_center_points(points_index_centers,...
    clust_nbr,varargin)

%3D data!!
if size(points_index_centers,2)==5
    
    %TOISTAISEKSI 3D:ssä VAAN YHEN ISON CLUSTERIN KESKIKOHDAN LASKUUN!!! PITÄÄ
    %UPSCALETTAA JOSSAIN KOHTI!! Samalla tavalla vaan ku tuo 2D, ei vaan
    %jaksanu tehä ku ei ollu ajankohtasta.. Pysyy mieli virkeenä ku jättää
    %paskahommia tulevaisuuteen ;)
    pts_cell={};
    
    sizes=0;
    for i=1:numel(clust_nbr)
        if clust_nbr(i) ~=-1
            
            %Searching all indexes which match the cluster class number
            %and calculating the center values of them.
            idx=find(points_index_centers(:,4)==clust_nbr(i));
            %tallenna koko jotenki!! ja ehkä matkat myös?
    
            %Only uses the clusters which have more than 1000 datapoints
            if length(idx)>1000
                xval=round(((max(points_index_centers(idx,1))+min(points_index_centers(idx,1)))/2));
                yval=round(((max(points_index_centers(idx,2))+min(points_index_centers(idx,2)))/2));
                zval=round(((max(points_index_centers(idx,3))+min(points_index_centers(idx,3)))/2));
                pts_cell={[xval,yval,zval]};
                sizes=length(idx);
            end
        end
    end
    
else 
    %2D data
    
    %For pixel --> micrometer conversion
    pixA=(1/varargin{1})*(1/varargin{1});

    pts_cell=[];
    sizes=[];
    for i=1:length(clust_nbr)
        if clust_nbr(i)~=-1
            idx=find(points_index_centers(:,3)==clust_nbr(i));
            xval=round((max(points_index_centers(idx,1))+min(points_index_centers(idx,1)))/2);
            yval=round(((max(points_index_centers(idx,2))+min(points_index_centers(idx,2)))/2));
            pts_cell(end+1,1:2)=[xval,yval];
            sizes(end+1,1)=length(idx)*pixA;

        end
    end
end
