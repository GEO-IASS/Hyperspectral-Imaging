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
        flatfieldGainGraph
        flatfieldGraph
        band
    end
    methods
    	function obj = processor()
            obj.band = 550;
            obj.flatfieldGraph = 0;
            obj.avgNumber = 2;
            obj.saveLocation = 'C:/';
            obj.title = 'test';
            obj.picNumber = 33;
            obj.originalGraph = 0;
            obj.flatfieldAvgGraph = 0;
            obj.flatfieldGainGraph = 0;
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
            obj.photoAvg('white', 'whiteavg');
            obj.photoAvg('reflect', 'reflectavg');
            msgbox('Series Averaging Completed')
        end
        function photoAvg(obj, picType, newType)
            counter = 1;
            img = load(defaults.cubeLocation(obj.location, obj.title, picType, int2str(counter)));
            counter = 2;
            while counter < obj.avgNumber
                add = load(defaults.cubeLocation(obj.location, obj.title, picType, int2str(counter)));
                img = uint64(img) + uint64(add);
                counter = counter + 1;
            end
            img = uint16(img/obj.avgNumber);
            save(defaults.cubeLocation(obj.location, obj.title, newType, '0'), img);
        end
        function graph(obj)
            values = zeros(1, obj.picNumber);
            if obj.originalGraph == 1
                img = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'avg', int2str(0)));
            elseif obj.flatfieldGraph == 1
                img = load(defaults.cubetLocation(obj.saveLocation, obj.title, 'flatfield', int2str(0)));
            elseif obj.flatfieldAvgGraph == 1
                img = load(defaults.cubetLocation(obj.saveLocation, obj.title, 'flatfieldAvg', int2str(0)));
            elseif obj.flatfieldGainGraph == 1
                img = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'flatfieldGain', int2str(0)));
            else
                img = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'corrected', int2str(0)));
            end
            counter;
            while counter <= obj.picNumber
                values(counter) = processor.rectanglePixelAvg(obj.X - obj.XRadius, obj.Y - obj.YRadius, obj.X + obj.XRadius, obj.Y + obj.YRadius, img(:, :, counter));
                if obj.percentGraph
                    whiteReference = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'whiteavg', int2str(0)));
                    values(counter) = uint16((uint64(values(counter)) * uint64(100))/uint64(processor.rectanglePixelAvg(obj.X - obj.XRadius, obj.Y - obj.YRadius, ...
                        obj.X + obj.XRadius, obj.Y + obj.YRadius, whiteReference(:, :, counter))));
                end
            end
            plot(obj.waveAxis, values);
            msgbox('Graph Completed')
        end
        function darkSeries(obj)
            counter = 1;
            while counter <= obj.picNumber
               img = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'avg', '0'));
               darkimg = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkavg', '0'));
               white = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'whiteavg', '0'));
               reflect = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'reflectavg', '0'));
               darksub = img - darkimg;
               darkwhite = white - darkimg;
               darkreflect = reflect - darkimg;
               imwrite(defaults.cubeLocation(obj.saveLocation, obj.title, 'darksub', '0'), darksub);
               imwrite(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkwhite', '0'), darkwhite);
               imwrite(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkreflect', '0'), darkreflect);
               counter = counter + 1;
            end
            msgbox('Dark Subtract Series Completed')
        end
        function flatFieldSeries(obj)
            img = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'darksub', '0'));
            reflect = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkreflect', '0'));
            white = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkwhite', '0'));
            trueLight = repmat(max(max(white)), 520, 696);
            img = uint16(uint64(img) * uint64(trueLight) * uint64(defaults.flatConstant()) / uint64(white));
            reflect = uint16(uint64(reflect) * uint64(trueLight) * uint64(defaults.flatConstant()) / uint64(white));
            imwrite(defaults.cubeLocation(obj.saveLocation, obj.title, 'flatfield', '0'), img);
            imwrite(defaults.cubeLocation(obj.saveLocation, obj.title, 'flatreflect', '0'), reflect);
            msgbox('Flat Field Series Completed')
        end
        function binSeries(obj)
           img = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'avg', '0'));
           darkimg = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkavg', '0'));
           whiteimg = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'whiteavg', '0'));
           bin = imresize(img, 1/(2^obj.binNumber));
           darkbin = imresize(darkimg, 1/(2^obj.binNumber));
           whitebin = imresize(whiteimg, 1/(2^obj.binNumber));
           save(defaults.cubeLocation(obj.saveLocation, obj.title, 'bin', '0'), bin);
           save(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkbin', '0'), darkbin);
           save(defaults.cubeLocation(obj.saveLocation, obj.title, 'whitebin', '0'), whitebin);
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
        function value = getflatfieldGainGraph(obj)
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
        function value = getFlatfieldGraph(obj)
            value = obj.flatfieldGraph;
        end
        function setFlatfieldGraph(obj, value)
            obj.flatfieldGraph = value;
            msgbox('Flatfield Graphing Modified')
        end
        function setFlatfieldGainGraph(obj, value)
            obj.flatfieldGainGraph = value;
            msgbox('Flatfield Gain Graphing Modified')
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
        function value = getBand(obj)
            value = obj.band;
        end
        function setBand(obj, value)
            obj.band = value;
            msgbox('Band Modified')
        end
        function colorCorrect(obj)
           img = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'flatfield', int2str(0)));
           reflect = load(defaults.cubeLocation(obj.saveLocation, obj.title, 'flatreflect', int2str(0)));
           img = uint16(uint64(img) * 0.99 / uint64(reflect));
           save(defaults.cubeLocation(obj.saveLocation, obj.title, 'correct', int2str(0)), img);
           msgbox('Color Correction Completed')
        end
        function imgDisplay(obj)
            img = imread(defaults.defaultLocation(obj.saveLocation, obj.title, 'flatfield', int2str(obj.band), int2str(0)));
            axes(handles.graphAxes), cla;
            imagesc(img), colormap (gray)
            axis image;
        end
        function convertToCube(obj, setType, setNum)
           counter = 1;
           cube = imread(defaults.defaultLocation(obj.saveLocation, obj.title, setType, int2str(obj.waveAxis(counter)), int2str(setNum)));
           counter = 2;
           while counter <= obj.picNumber
               img = imread(defaults.defaultLocation(obj.saveLocation, obj.title, setType', int2str(obj.waveAxis(counter)), int2str(setNum)));
               cube = cat(3, cube, img);
               counter = counter + 1;
           end
           save(defaults.cubeLocation(obj.saveLocation, obj.title, setType, int2str(setNum)), cube);
        end
        function convertCube(obj)
           counter = 1;
           while counter <= obj.avgNumber
               convertToCube(obj, 'reg', counter);
               convertToCube(obj, 'dark', counter);
               convertToCube(obj, 'white', counter);
               counter = counter + 1;
           end
        end
        function convertENVI(obj)
           enviwrite(defaults.cubeLocation(obj.saveLocation, obj.title, 'avg', '0'), defaults.ENVILocation(obj.saveLocation, obj.title, 'avg', '0')); 
           enviwrite(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkavg', '0'), defaults.ENVILocation(obj.saveLocation, obj.title, 'darkavg', '0')); 
           enviwrite(defaults.cubeLocation(obj.saveLocation, obj.title, 'whiteavg', '0'), defaults.ENVILocation(obj.saveLocation, obj.title, 'whiteavg', '0')); 
           enviwrite(defaults.cubeLocation(obj.saveLocation, obj.title, 'flatfield', '0'), defaults.ENVILocation(obj.saveLocation, obj.title, 'flatfield', '0')); 
           enviwrite(defaults.cubeLocation(obj.saveLocation, obj.title, 'flatfieldAvg', '0'), defaults.ENVILocation(obj.saveLocation, obj.title, 'flatfieldAvg', '0')); 
           enviwrite(defaults.cubeLocation(obj.saveLocation, obj.title, 'flatFieldGain', '0'), defaults.ENVILocation(obj.saveLocation, obj.title, 'flatFieldGain', '0')); 
           enviwrite(defaults.cubeLocation(obj.saveLocation, obj.title, 'darksub', '0'), defaults.ENVILocation(obj.saveLocation, obj.title, 'darksub', '0')); 
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