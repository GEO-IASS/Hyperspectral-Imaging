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
        step
    end
    methods
        function obj = scanner()
            obj.avgNumber = 2;
            obj.camera = camera();
            obj.filter = filter();
            obj.saveLocation = 'C:/';
            obj.title = 'test';
            obj.step = 10;
            obj.picNumber = 33;
            %Intrapolate extended gain and exposure curves
            obj.exposureCurve = interp1(defaults.getSimpleEcurve(), 1:0.1:33);
            obj.gainCurve = interp1(defaults.getSimpleGcurve(), 1:0.1:33);
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
        function takeSet(obj, setType, handles)
            if obj.camera.isConnected() && obj.filter.isConnected()
                setNum = 0;
                while(setNum < obj.avgNumber)
                    pause(defaults.longdelay());
                    for picID=1:length(obj.waveAxis)
                        obj.setGain(obj.gainCurve(obj.waveAxis(picID)-399));
                        set(handles.gainText, 'String', ['Gain: ', int2str(obj.camera.getGain())]);		
                        obj.setExposure(obj.exposureCurve(obj.waveAxis(picID) - 399));
%                         obj.camera.autoSetExposure();
                        set(handles.exposureText, 'String', ['Exposure Time: ', int2str(obj.camera.getExposure())]);		
                        obj.setWavelength(obj.waveAxis(picID)); 
                        set(handles.wavelengthText, 'String', ['Wavelength: ', int2str(obj.filter.getWavelength())]);		
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
        function setPicNumber(obj, step)
            if (320/double(step)) == round((320/double(step)))
                obj.picNumber = 1 + (320/step);
                obj.waveAxis = uint16(linspace(400, 720, obj.picNumber));
                obj.step = step;
                msgbox('Wavelength Step Modified')
            else
                msgbox('Cannot Modify, Rounding to Closest Interval')
                step = defaults.closestFactor(320, step);
                obj.step = step;
                obj.picNumber = (320/step) + 1;
                obj.waveAxis = uint16(linspace(400, 720, obj.picNumber));
                msgbox(['Wavelength Step Modified:', int2str(step)])
            end
        end
        function picNumber = getPicNumber(obj)
            picNumber = obj.picNumber;
        end
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
                simpleGcurve= defaults.getSimpleGcurve();
                %Set default exposure curve in ms
                simpleEcurve= defaults.getSimpleEcurve();
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
