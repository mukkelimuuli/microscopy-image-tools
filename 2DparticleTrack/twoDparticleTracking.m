%Aja vain ensimmäinen osa CTRL+ENTER, kun vasemmalla palkissa vain
%ensimmäinen osa näkyy sinisenä. Kun ajettu, aja toinen osa klikkaamalla
%mitä vaan riviä >30 ja paina uudestaan CTRL+ENTER

%Kun segmentointi on kerran tehty, ei ensimmäistä osaa ole syytä ajaa 
%uudestaan!


%Luetaan filu
[filename, pathname] = uigetfile('*.*', 'Select a File');
fullpath = fullfile(pathname, filename);
separateChannels=dataFromOir(fullpath);

%Otetaan pelkästään toinen kanava
sarja=squeeze(separateChannels(:,:,:,2));

%Aikasarja 27-35 liike mitä halutaan seurata ImageJ tarkastelun perusteella
%                         v     laitetaan tohon
valittu_sarja=sarja(:,:,27:35);

%Käydään kaikki valitut kuvat läpi sarjasta ja rajataan alle 1200
%intensiteetit pois kuvasta, jotta helpompi segmentoida. For loop
%käy kuvat käänteisessä järjestyksessä, jotta segmentointi ikkunat
%voi käydä läpi siinä järjestyksessä, jossa ne aukeaa MATLAB:iin.
intensiteetti_alaraja=1200;
for i=flip(1:size(valittu_sarja,3))   
    liike=squeeze(valittu_sarja(:,:,i));
    liike(liike <= intensiteetti_alaraja ) = 0;
    imageSegmenter(rescale(liike, 0, 1));
end


%% 
%Etsii muuttujista segmentoidut kuvat joiden nimessä on 'BW'
myvars=who;
bw_vars = myvars(startsWith(myvars, 'BW'));
lkm_BW=size(bw_vars,1);


% Käy läpi segmentoidut kuvat ja laskee keskikohdan segmentoidulle alueelle
% trackausta varten ja trackaa pisteen liikkeen.
midpoint=cell{1,lkm_BW};
for i=1:size(bw_vars)
    var=eval(bw_vars{i});
    [x,y]=find(var==1);
    pt=[round(mean(x)),round(mean(y))];
    midpoint{1,i}=pt;
end

%Simpletracker algoritmi laskee annettujen pisteiden yhteyden ja linkkaa
%ne keskenään
[tracks,adjacency_tracks]=simpletracker(midpoint);


%Piirretään liike
n_tracks = numel(tracks);
colors = hsv(n_tracks);
all_points = vertcat(midpoint{:});

for i_track = 1 : n_tracks    
    track = adjacency_tracks{i_track};
    track_points = all_points(track, :);
    plot(track_points(:,1),track_points(:, 2), 'Color', colors(i_track, :))
    
end


%Piirretään 2D path kuvaan pointtejen perusteella!

pohja=zeros(512,512);

for i=1:size(track_points,1)-1
    [x,y]=bresenham_2d(track_points(i,1),track_points(i,2), ...
        track_points(i+1,1),track_points(i+1,2));
    for k=1:size(x,1)
        pohja(x(k),y(k))=1;
    end
end

%Piirretään sarjan viimeinen valittu kuva ja partikkelin kulkema reitti
viimenen_kuva_ja_reitti=sarja(:,:,35)+pohja*10000;
figure;
imagesc(viimenen_kuva_ja_reitti);
