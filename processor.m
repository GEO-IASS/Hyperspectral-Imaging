classdef processor < handle
    properties (Access = private)
        avgNumber %Number of photo sets to average
        saveLocation
        title %Title of set
        picNumber %Number of pictures per set
        X %Graphing square center
        Y
        flatfieldAvgGraph %Graph flatfielded set instead of contrast set
        percentGraph
        originalGraph %Graph original set instead of contrast set
        waveAxis %Wavelength array
        XRadius %Radius of graphing region on each axis
        YRadius
        gainCurve
        binNumber
    end
    methods
    	function obj = processor()
            obj.avgNumber = 2;
            obj.saveLocation = 'C:/';
            obj.title = 'test';
            obj.picNumber = 33;
            obj.originalGraph = 0;
            obj.flatfieldAvgGraph = 0;
            obj.percentGraph = 0;
            obj.X = 1;
            obj.Y = 1;
            obj.XRadius = 0;
            obj.YRadius = 0;
            obj.waveAxis = uint16(linspace(400, 720, 33));
            simpleGcurve = ones(1, 33) * 1;
            obj.gainCurve = interp1(simpleGcurve, 1:0.1:33);
            obj.binNumber = 0;
        end
        function setTitle(obj, input)
            obj.title = input;
            msgbox('Title Modified')
        end
        function title = getTitle(obj)
            title = obj.title;
        end
    	function setSaveLocation(obj, saveLocation)
            obj.saveLocation = saveLocation;
            msgbox('Save Location Modified')
            if obj.saveLocation(size(saveLocation)) ~= '/'
               obj.saveLocation = strcat(obj.saveLocation, '/');
            end
        end
        function saveLocation = getSaveLocation(obj)
            saveLocation = obj.saveLocation;
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
        function displaySettings(obj)
            msgbox({['Number: ' num2str(obj.picNumber)]; ...
                ['Title: ' obj.title]; ['Location: ' obj.saveLocation];})
        end
        function avgProduction(obj)
    		obj.photoAvg('reg', 'avg');
            obj.photoAvg('dark', 'darkavg');
            obj.photoAvg('white', 'whiteavg')
            msgbox('Series Averaging Completed')
        end
        function photoAvg(obj, picType, newType)
            setCounter = 1;
            picNumberCount = 1;
            while picNumberCount <= obj.picNumber
                avgSet = imread(defaults.defaultLocation(obj.saveLocation, obj.title, ...
                    picType, int2str(obj.waveAxis(picNumberCount)), int2str(setCounter)));
                avgSet = uint64(avgSet);
                setCounter = 2;
                while setCounter <= obj.avgNumber
                    addon = imread(defaults.defaultLocation(obj.saveLocation, obj.title, picType, ...
                        int2str(obj.waveAxis(picNumberCount)), int2str(setCounter)));
                    avgSet = avgSet + uint64(addon);
                    setCounter = setCounter + 1;
                end
                setCounter = 1;
                avgSet = avgSet / obj.avgNumber;
                imwrite(uint16(avgSet), defaults.defaultLocation(obj.saveLocation, obj.title, ...
                    newType, int2str(obj.waveAxis(picNumberCount)), int2str(0)));
                picNumberCount = picNumberCount + 1;
            end
        end
        function graph(obj)
            wavelength = 1;
            values = zeros(1, obj.picNumber);
            while wavelength <= obj.picNumber
                if obj.originalGraph == 1
                    img = imread(defaults.defaultLocation(obj.saveLocation, obj.title, 'avg', int2str(obj.waveAxis(wavelength)), int2str(0)));
                elseif obj.flatfieldAvgGraph == 1
                    img = imread(defaults.defaultLocation(obj.saveLocation, obj.title, 'flatfieldAvg', int2str(obj.waveAxis(wavelength)), int2str(0)));
                else
                    img = imread(defaults.defaultLocation(obj.saveLocation, obj.title, 'flatfield', int2str(obj.waveAxis(wavelength)), int2str(0)));
                end
                values(wavelength) = processor.rectanglePixelAvg(obj.X - obj.XRadius, obj.Y - obj.YRadius, obj.X + obj.XRadius, obj.Y + obj.YRadius, img);
                if obj.percentGraph
                    whiteReference = imread(defaults.defaultLocation(obj.saveLocation, obj.title, 'whiteavg', int2str(obj.waveAxis(wavelength)), int2str(0)));
                    values(wavelength) = uint16((uint64(values(wavelength)) * uint64(100))/uint64(processor.rectanglePixelAvg(obj.X - obj.XRadius, obj.Y - obj.YRadius, ...
                        obj.X + obj.XRadius, obj.Y + obj.YRadius, whiteReference)));
                end
                wavelength = wavelength + 1;
            end
            plot(obj.waveAxis, values);
            msgbox('Graph Completed')
        end
        function darkSeries(obj)
            counter = 1;
            while counter <= obj.picNumber
               img = imread(defaults.defaultLocation(obj.saveLocation, obj.title, 'avg', int2str(obj.waveAxis(counter)), '0'));
               darkimg = imread(defaults.defaultLocation(obj.saveLocation, obj.title, 'darkavg', int2str(obj.waveAxis(counter)), '0'));
               darksub = imsubtract(img, darkimg);
               imwrite(darksub, defaults.defaultLocation(obj.saveLocation, obj.title, 'darksub', int2str(obj.waveAxis(counter)), '0'));
               counter = counter + 1;
            end
            msgbox('Dark Subtract Series Completed')
        end
        function flatFieldSeries(obj)
            counter = 1;
            while counter <= obj.picNumber
                wavelength = obj.waveAxis(counter);
                obj.flatFieldCorrection(wavelength);
                counter = counter + 1;
            end
            msgbox('Flat Field Series Completed')
        end
        function binSeries(obj)
           counter = 1;
           while counter <= obj.picNumber
               img = imread(defaults.defaultLocation(obj.saveLocation, obj.title, 'avg', int2str(obj.waveAxis(counter)), '0'));
               darkimg = imread(defaults.defaultLocation(obj.saveLocation, obj.title, 'darkavg', int2str(obj.waveAxis(counter)), '0'));
               whiteimg = imread(defaults.defaultLocation(obj.saveLocation, obj.title, 'whiteavg', int2str(obj.waveAxis(counter)), '0'));
               bin = imresize(img, 1/(2^obj.binNumber));
               darkbin = imresize(darkimg, 1/(2^obj.binNumber));
               whitebin = imresize(whiteimg, 1/(2^obj.binNumber));
               imwrite(bin, defaults.defaultLocation(obj.saveLocation, obj.title, 'bin', int2str(obj.waveAxis(counter)), '0'));
               imwrite(darkbin,defaults.defaultLocation(obj.saveLocation, obj.title, 'darkbin', int2str(obj.waveAxis(counter)), '0'));
               imwrite(whitebin,defaults.defaultLocation(obj.saveLocation, obj.title, 'whitebin', int2str(obj.waveAxis(counter)), '0'));
               counter = counter + 1;
           end
           msgbox('Binned Series Completed')
        end
        function x = getX(obj)
            x = obj.X;
        end
        function y = getY(obj)
            y = obj.Y;
        end
        function setX(obj, x)
            obj.X = x;
            msgbox('Center X Modified')
        end
        function setY(obj, y)
            obj.Y = y;
            msgbox('Center Y Modified')
        end
        function value = getBinNumber(obj)
            value = obj.binNumber;
        end
        function setBinNumber(obj, input)
            if(input <= 3 && input >= 0)
                obj.binNumber = input;
                msgbox('Bin Number Modified')
            else
               errordlg('Bin Number Must be [0, 3] - Set to 0')
               obj.binNumber = 0;
            end
        end
        function value = getflatfieldAvgGraph(obj)
            value = obj.flatfieldAvgGraph;
        end
        function value = getPercentGraph(obj)
            value = obj.percentGraph;
        end
        function value = getOriginalGraph(obj)
            value = obj.originalGraph;
        end
        function setFlatfieldAvgGraph(obj, value)
            obj.flatfieldAvgGraph = value;
            msgbox('Flatfield Average Graphing Modified')
        end
        function setOriginalGraph(obj, value)
            obj.originalGraph = value;
            msgbox('Original-Graphing Modified')
        end
        function setPercentGraph(obj, value)
            obj.percentGraph = value;
            msgbox('Percent-Graphing Modified')
        end
        function setXRadius(obj, value)
            if value < 0
                errordlg('Value must be >= 0, set to 0')
                obj.XRadius = 0;
            else
                obj.XRadius = value;
                msgbox('X Radius Modified')
            end
        end
        function value = getXRadius(obj)
            value = obj.XRadius;
        end
        function setYRadius(obj, value)
            if value < 0
                errordlg('Value must be >= 0, set to 0')
                obj.YRadius = 0;
            else
                obj.YRadius = value;
                msgbox('Y Radius Modified')
            end
        end
        function value = getYRadius(obj)
            value = obj.YRadius;
        end
        function value = getGain(obj)
            value = mean(obj.gainCurve);
        end
        function setGain(obj, value)
            simpleGcurve = ones(1, 33) * value;
            obj.gainCurve = interp1(simpleGcurve, 1:0.1:33);
            msgbox('Gain Modified')
        end
        function flatFieldCorrection(obj, wavelength)
            dark = imread(defaults.defaultLocation(obj.saveLocation, obj.title, 'darkavg', int2str(wavelength), int2str(0)));
            flat = imread(defaults.defaultLocation(obj.saveLocation, obj.title, 'whiteavg', int2str(wavelength), int2str(0)));
            darksub = imread(defaults.defaultLocation(obj.saveLocation, obj.title, 'darksub', int2str(wavelength), int2str(0)));
            darkFlat = imsubtract(flat, dark);
            meanCalc = mean(darkFlat(:));
            corrected1 = uint16(imdivide((uint64(meanCalc)* uint64(darksub)), uint64(darkFlat)));
            corrected2 = uint16(immultiply(uint64(darksub), mean(obj.gainCurve)));
            imwrite(corrected1, defaults.defaultLocation(obj.saveLocation, obj.title, 'flatfieldAvg', int2str(wavelength), int2str(0)));
            imwrite(corrected2, defaults.defaultLocation(obj.saveLocation, obj.title, 'flatfield', int2str(wavelength), int2str(0)));
        end
    end
    methods (Static)
        function n = rectanglePixelAvg(minX, minY, maxX, maxY, img)
            x = minX;
            y = minY;
            average = uint64(0);
            while x <= maxX
                while y <= maxY
                    average = average + uint64(img(y, x));
                    y = y + 1;
                end
                y = minY;
                x = x + 1;
            end
            n = uint16(average / uint64((maxX - minX + 1) * (maxY - minY + 1)));
        end
    end
end