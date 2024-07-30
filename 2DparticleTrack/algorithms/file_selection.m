function separateChannels=file_selection(lastThreeChars,fullpath,varargin)
    if lastThreeChars == "czi" || lastThreeChars =="oir" || lastThreeChars == "nd2" || lastThreeChars=="tif"
        if lastThreeChars =="czi"
            %varargin determines if all the timepoints are used
            if ~isempty(varargin)
                separateChannels=dataFromCzi(fullpath,1);
            else
                separateChannels=dataFromCzi(fullpath);
            end
        elseif lastThreeChars =="oir"
            if ~isempty(varargin)
                separateChannels=dataFromOir(fullpath,1);
            else
                separateChannels=dataFromOir(fullpath);
            end
        elseif lastThreeChars == "tif"
            separateChannels=tiffreadVolume(fullpath);
        else
            separateChannels=dataFromNd2(fullpath);
        end
    end
end