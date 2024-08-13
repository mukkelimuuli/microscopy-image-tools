%KAIKEN LASKEMISEEN TÄÄLLÄ TARVII

function output=dist_calc(fI,cp,s_eca)

    %FI on center + repimisosat
    %eli tässä lasketaan vaan fI reunat ja lasketaan etäisyys  centeristä
    %erotus lasketaan kans!
    
    outern_edges=edge(fI,"canny");
    [row,col]=find(outern_edges==1);

    le=length(row);
    
    outern_eca=zeros(le,3);
    outern_eca(:,1)=row;
    outern_eca(:,2)=col;

    for i = 1:le
        outern_eca(i,3)=atan2(cp(2)-col(i),cp(1)-row(i))*180/pi;
    end

    %Vois tehä vektorin, johon laskee järjestyksessä ulkoreunapisteiden
    %etäisyydet keskiöstä ja sit pitäs saada matchattua jotenki kulmien
    %kanssa jotka on s_ecassa!! sit etäisyyksien erotukset pitää laskee
    %output variableen ja palauttaa!! TaDAA

    % Initialize an array to store distances
    distances = zeros(size(s_eca, 1), 1);

    for i = 1:size(s_eca, 1)
        % Find the closest s_ecangle in outern_eca to the current angle in A
        [~, idx] = min(abs(outern_eca(:, 3) - s_eca(i, 3)));
        
        % Calculate the Euclidean distance between the coordinates
        distances(i) = norm([outern_eca(idx, 1) - s_eca(i, 1),...
            outern_eca(idx, 2) - s_eca(i, 2)]);
    end
    output=distances;
end