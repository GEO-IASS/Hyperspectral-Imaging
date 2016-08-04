classdef scanner < handle
    properties (Access = private)
        avgNumber
        camera
        filter
        saveLocation
        title
        picNumber
        waveAxis
        gainCurve
        exposureCurve
        constantSettings
    end
    methods
        function obj = scanner()
            obj.avgNumber = 2;
            obj.camera = camera();
            obj.filter = filter();
            obj.saveLocation = 'C:/';
            obj.title = 'test';
            obj.picNumber = 33;
            % Set default gain curve
            simpleGcurve=[30.0 26.0 22.0 18.0 14.0 10.0 8.0 6.0 4.0 ...
            3.0 2.0 1.8 1.6 1.4 1.2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
            %Set default exposure curve in ms
            simpleEcurve=[1000 1000 1000 1000 1000 1000 900 800 700 600 ...
            500 400 300 200 150 150 150 150 150 150 150 150 150 150 150 ...
            150 150 150 150 150 150 150 150];
            %Intrapolate extended gain and exposure curves
            obj.exposureCurve = interp1(simpleEcurve, 1:0.1:33);
            obj.gainCurve = interp1(simpleGcurve, 1:0.1:33);
            obj.waveAxis = linspace(400, 720, 33);
            obj.waveAxis = uint16(obj.waveAxis);
            obj.constantSettings = 0;
        end
        function setAvgNumber(obj, avgNumber)
            if isnan(avgNumber)
                errordlg('Correction factor value must be a number')
            elseif avgNumber < 1 || avgNumber > 15
                errordlg('Correction factor value must be within 1 to 15 inclusive.')
            else
                obj.avgNumber = avgNumber;
                msgbox('Averaging Number Modified')
            end
        end
        function avgNumber = getAvgNumber(obj)
            avgNumber = obj.avgNumber;
        end
        function connect(obj)
           obj.camera.connect();
           obj.filter.connect();
        end
        function disconnect(obj)
            obj.camera.disconnect();
            obj.filter.disconnect();
        end
        function setExposure(obj, exposure)
            if ~obj.camera.isConnected()
                errordlg('Camera Not Connected')
            elseif isnan(exposure)
                errordlg('Exposure value must be a number')
            elseif exposure < 0 || exposure > 1000
                errordlg('Exposure value must be within 0 to 1000 ms inclusive.')
            else
                obj.camera.setExposure(exposure);
                if obj.constantSettings
                    simpleEcurve = ones(1, 33) * exposure;
                    obj.exposureCurve = interp1(simpleEcurve, 1:0.1:33);
                end
            end
        end
        function setGain(obj, gain)
            if ~obj.camera.isConnected()
                errordlg('Camera Not Connected')
            elseif isnan(gain)
                errordlg('Gain value must be a number')
            elseif gain < 0 || gain > 30
                errordlg('Gain value must be within 0 to 30 inclusive.')
            else
                obj.camera.setGain(gain);
                if obj.constantSettings
                    simpleGcurve= ones(1, 33) * gain;
                    obj.gainCurve = interp1(simpleGcurve, 1:0.1:33);
                end
            end
        end
        function setWavelength(obj, wavelength)
            if ~obj.filter.isConnected()
                errordlg('Filter Not Connected')
            elseif isnan(wavelength)
                errordlg('Wavelength value must be a number')
            elseif wavelength < 400 || wavelength > 720
                errordlg('Wavelength value must be within 400 to 720 ms inclusive.')
            else
                obj.filter.setWavelength(wavelength);
            end
        end
        function setSaveLocation(obj, saveLocation)
            obj.saveLocation = saveLocation;
            if obj.saveLocation(size(saveLocation)) ~= '/'
               obj.saveLocation = strcat(obj.saveLocation, '/');
            end
            if ~exist(saveLocation, 'dir')
                mkdir(saveLocation);
            end
            msgbox('Save Location Modified')
        end
        function saveLocation = getSaveLocation(obj)
            saveLocation = obj.saveLocation;
        end
        function takePicture(obj, setType, setNum)
            if (strcmp(setType, 'sing') && obj.filter.isConnected() && obj.camera.isConnected()) || ~strcmp(setType, 'sing')
                img = obj.camera.takePicture();
                if strcmp(setType, 'sing')
                    imwrite(img, [obj.saveLocation, obj.title, '-', date, '-', ...
                    int2str(obj.filter.getWavelength()),'-',int2str(obj.camera.getGain()),'-', ...
                    int2str(obj.camera.getExposure()),'.tif']);
                else
                    imwrite(img, defaults.defaultLocation(obj.saveLocation, obj.title, setType, ...
                    int2str(obj.filter.getWavelength()), int2str(setNum)));
                end
                pause(defaults.longdelay());
            elseif obj.filter.isConnected()
                errordlg('Please Connect Camera First')
            else
                errordlg('Please Connect Filter First')
            end
        end
        function setTitle(obj, title)
            obj.title = title;
            msgbox('Title Modified')
        end
        function title = getTitle(obj)
            title = obj.title;
        end
        function takeSet(obj, setType)
            if obj.camera.isConnected() && obj.filter.isConnected()
                setNum = 0;
                while(setNum < obj.avgNumber)
                    pause(defaults.longdelay());
                    for picID=1:length(obj.waveAxis)
                        %Set gain
                        obj.setGain(obj.gainCurve(obj.waveAxis(picID)-399));
                        obj.setExposure(obj.exposureCurve(obj.waveAxis(picID) - 399));     
                        obj.setWavelength(obj.waveAxis(picID)); 
                        obj.takePicture(setType, setNum + 1);
                    end
                    setNum = setNum + 1;
                end
            elseif obj.filter.isConnected()
                errordlg('Please Connect Camera First')
            else
                errordlg('Please Connect Filter First')
            end
        end
        function setPicNumber(obj, picNumber)
            if (320/double(picNumber - 1)) == round((320/double(picNumber - 1)))
                obj.picNumber = picNumber;
                obj.waveAxis = uint16(linspace(400, 720, obj.picNumber));
                msgbox('Picture Number Modified')
            else
                msgbox('Cannot Modify, Rounding to Closest Interval')
                obj.picNumber = defaults.closestFactor(320, picNumber - 1) + 1;
                obj.waveAxis = uint16(linspace(400, 720, obj.picNumber));
                msgbox(['Picture Number Modified:', int2str(obj.picNumber)])
            end
        end
        function picNumber = getPicNumber(obj)
            picNumber = obj.picNumber;
        end
%         function displaySettings(obj)
%             if obj.camera.isConnected() && obj.filter.isConnected()
%                 msgbox({['Gain: ' num2str(obj.camera.getGain())]; ['Exposure Time: ' ...
%                     num2str(obj.camera.getExposure())]; ...
%                     ['Wavelength: ' num2str(obj.filter.getWavelength())]; ...
%                     ['Number: ' num2str(obj.picNumber)]; ...
%                     ['Title: ' obj.title]; ['Location: ' obj.saveLocation];})
%             elseif obj.filter.isConnected()
%                 errordlg('Please Connect Camera First')
%             else
%                 errordlg('Please Connect Filter First')
%             end
%         end
        function appxFromWave(obj)
            obj.setGain(obj.gainCurve(obj.filter.getWavelength() - 399));
            obj.setExposure(obj.exposureCurve(obj.filter.getWavelength() - 399));
            msgbox(['Settings Adjusted. Gain: ' num2str(obj.camera.getGain()) ...
                ', Exposure Time: ' num2str(obj.camera.getExposure())])
        end
        function setConstantSettings(obj, value)
            obj.constantSettings = value;
            if obj.constantSettings
                if obj.camera.isConnected()
                    simpleGcurve= ones(1, 33) * obj.camera.getGain();
                    simpleEcurve = ones(1, 33) * obj.camera.getExposure();
                else
                    errordlg('Camera Not Connected: Setting to Defaults')
                    simpleGcurve= ones(1, 33) * 10;
                    simpleEcurve = ones(1, 33) * 500;
                end
                obj.exposureCurve = interp1(simpleEcurve, 1:0.1:33);
                obj.gainCurve = interp1(simpleGcurve, 1:0.1:33);
            else
                % Set default gain curve
                simpleGcurve=[30.0 26.0 22.0 18.0 14.0 10.0 8.0 6.0 4.0 ...
                3.0 2.0 1.8 1.6 1.4 1.2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
                %Set default exposure curve in ms
                simpleEcurve=[1000 1000 1000 1000 1000 1000 900 800 700 600 ...
                500 400 300 200 150 150 150 150 150 150 150 150 150 150 150 ...
                150 150 150 150 150 150 150 150];
                %Intrapolate extended gain and exposure curves
                obj.exposureCurve = interp1(simpleEcurve, 1:0.1:33);
                obj.gainCurve = interp1(simpleGcurve, 1:0.1:33);
            end
            msgbox('Constant Settings Modified')
        end
        function value = getConstantSettings(obj)
            value = obj.constantSettings;
        end
    end
end