classdef processor < handle
    properties (Access = private)
        avgNumber %Number of photo sets to average
        saveLocation
        title %Title of set
        picNumber %Number of pictures per set
        X %Graphing square center
        Y
        originalGraph %Graph original set instead of contrast set
        waveAxis %Wavelength array
        XRadius %Radius of graphing region on each axis
        YRadius
        binNumber
        flatfieldGraph
        band
        reflectDisplay
    end
    methods
    	function obj = processor()
            obj.reflectDisplay = 0;
            obj.band = 550;
            obj.flatfieldGraph = 0;
            obj.avgNumber = 2;
            obj.saveLocation = 'C:/';
            obj.title = 'test';
            obj.picNumber = 33;
            obj.originalGraph = 0;
%             obj.flatfieldAvgGraph = 0;
%             obj.flatfieldGainGraph = 0;
%             obj.percentGraph = 0;
            obj.X = 1;
            obj.Y = 1;
            obj.XRadius = 0;
            obj.YRadius = 0;
            obj.waveAxis = uint16(linspace(400, 720, 33));
%             simpleGcurve = ones(1, 33) * 1;
%             obj.gainCurve = interp1(simpleGcurve, 1:0.1:33);
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
        function setPicNumber(obj, step)
            if (320/double(step)) == round((320/double(step)))
                obj.picNumber = 1 + (320/step);
                obj.waveAxis = uint16(linspace(400, 720, obj.picNumber));
                msgbox('Wavelength Step Modified')
            else
                msgbox('Cannot Modify, Rounding to Closest Interval')
                step = defaults.closestFactor(320, step);
                obj.picNumber = (320/step) + 1;
                obj.waveAxis = uint16(linspace(400, 720, obj.picNumber));
                msgbox(['Wavelength Step Modified:', int2str(step)])
            end
        end
        function picNumber = getPicNumber(obj)
            picNumber = obj.picNumber;
        end
%         function displaySettings(obj)
%             msgbox({['Number: ' num2str(obj.picNumber)]; ...
%                 ['Title: ' obj.title]; ['Location: ' obj.saveLocation];})
%         end
        function avgProduction(obj)
    		obj.photoAvg('reg', 'avg');
            obj.photoAvg('dark', 'darkavg');
            obj.photoAvg('white', 'whiteavg');
            %obj.photoAvg('reflect', 'reflectavg');
            msgbox('Series Averaging Completed')
        end
        function photoAvg(obj, picType, newType)
            counter = 1;
            img = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, picType, int2str(counter)))));
            counter = 2;
            while counter <= obj.avgNumber
                add = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, picType, int2str(counter)))));
                img = double(img) + double(add);
                counter = counter + 1;
            end
            img = double(img) / double(obj.avgNumber);
            save(defaults.cubeLocation(obj.saveLocation, obj.title, newType, '0'), 'img');
        end
        function graph(obj)
            values = zeros(1, obj.picNumber);
            if obj.originalGraph == 1
                img = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'darksub', int2str(0)))));
            elseif obj.flatfieldGraph == 1
                img = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'flatfield', int2str(0)))));
            else
                img = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'correct', int2str(0)))));
            end
            counter = 1;
            binAmount = 1.0/(2 ^ obj.binNumber);
            while counter <= obj.picNumber
                values(counter) = obj.rectanglePixelAvg((obj.X - obj.XRadius), (obj.Y - obj.YRadius), (obj.X + obj.XRadius), (obj.Y + obj.YRadius), img(:, :, counter));
                counter = counter + 1;
            end
            plot(obj.waveAxis, values);
            msgbox('Graph Completed')
        end
        function darkSeries(obj)
           img = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'bin', '0'))));
           darkimg = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkbin', '0'))));
           white = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'whitebin', '0'))));
           %reflect = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'reflectbin', '0'))));
           darksub = img; - darkimg;
           darkwhite = white; - darkimg;
           %darkreflect = reflect - darkimg;
           save(defaults.cubeLocation(obj.saveLocation, obj.title, 'darksub', '0'), 'darksub');
           save(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkwhite', '0'), 'darkwhite');
           %save(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkreflect', '0'), 'darkreflect');
           msgbox('Dark Subtract Series Completed')
        end
        function flatFieldSeries(obj)
            img = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'darksub', '0'))));
            %reflect = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkreflect', '0'))));
            white = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkwhite', '0'))));
            trueLight = repmat(max(max(white)), 520 * double(1.0/(2^obj.binNumber)), 696 *  double(1.0/(2^obj.binNumber)));
            img = double(double(img) .* double(trueLight) * double(defaults.flatConstant()) ./ double(white));
            white = double(double(white) .* double(trueLight) * double(defaults.flatConstant()) ./ double(white));
            %reflect = uint16(uint64(reflect) .* uint64(trueLight) * uint64(defaults.flatConstant()) ./ uint64(white));
            save(defaults.cubeLocation(obj.saveLocation, obj.title, 'flatfield', '0'), 'img');
            save(defaults.cubeLocation(obj.saveLocation, obj.title, 'flatwhite', '0'), 'white');
            msgbox('Flat Field Series Completed')
        end
        function binSeries(obj)
           img = double(cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'avg', '0')))));
           darkimg = double(cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkavg', '0')))));
           whiteimg = double(cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'whiteavg', '0')))));
           sizeVector = double(1.0/(2^obj.binNumber));
           bin = imresize(img, sizeVector);
           darkbin = imresize(darkimg, sizeVector);
           whitebin = imresize(whiteimg, sizeVector);
           save(defaults.cubeLocation(obj.saveLocation, obj.title, 'bin', '0'), 'bin');
           save(defaults.cubeLocation(obj.saveLocation, obj.title, 'darkbin', '0'), 'darkbin');
           save(defaults.cubeLocation(obj.saveLocation, obj.title, 'whitebin', '0'), 'whitebin');
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
        function value = getOriginalGraph(obj)
            value = obj.originalGraph;
        end
        function value = getFlatfieldGraph(obj)
            value = obj.flatfieldGraph;
        end
        function setFlatfieldGraph(obj, value)
            obj.flatfieldGraph = value;
            msgbox('Flatfield Graphing Modified')
        end
        function setOriginalGraph(obj, value)
            obj.originalGraph = value;
            msgbox('Original-Graphing Modified')
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
        function value = getBand(obj)
            value = obj.band;
        end
        function setBand(obj, value)
            obj.band = value;
            msgbox('Band Modified')
        end
        function value = getReflectDisplay(obj)
            value = obj.reflectDisplay;
        end
        function setReflectDisplay(obj, value)
            obj.reflectDisplay = value;
            msgbox('Reflect Display Modified')
        end
        function colorCorrect(obj)
           img = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'flatfield', int2str(0)))));
           reflect = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, 'flatwhite', int2str(0)))));
           reflectVal = zeros(1, obj.picNumber);
           counter = 1;
           while counter <= obj.picNumber
               reflectVal(counter) = obj.rectanglePixelAvg(obj.X - obj.XRadius, obj.Y - obj.YRadius, obj.X + obj.XRadius, obj.Y + obj.YRadius, reflect(:, :, counter));
               counter = counter + 1;
           end
           counter = 1;
           while counter <= obj.picNumber
               img(:, :, counter) = double(double(img(:, :, counter)) * defaults.stdReflectance() / double(reflectVal(counter)));
               counter = counter + 1;
           end
           save(defaults.cubeLocation(obj.saveLocation, obj.title, 'correct', int2str(0)), 'img');
           msgbox('Color Correction Completed')
        end
        function convertToCube(obj, setType, setNum)
           counter = 1;
           cube = imread(defaults.defaultLocation(obj.saveLocation, obj.title, setType, int2str(obj.waveAxis(counter)), int2str(setNum)));
           counter = 2;
           while counter <= obj.picNumber
               img = imread(defaults.defaultLocation(obj.saveLocation, obj.title, setType, int2str(obj.waveAxis(counter)), int2str(setNum)));
               cube = cat(3, cube, img);
               counter = counter + 1;
           end
           save(defaults.cubeLocation(obj.saveLocation, obj.title, setType, int2str(setNum)), 'cube');
        end
        function convertCube(obj)
           counter = 1;
           while counter <= obj.avgNumber
               convertToCube(obj, 'reg', counter);
               convertToCube(obj, 'dark', counter);
               convertToCube(obj, 'white', counter);
               %convertToCube(obj, 'reflect', counter);
               counter = counter + 1;
           end
           msgbox('Data Converted to .mat Data Cubes')
        end
        function convertENVI(obj)
           obj.ENVI('avg');
           obj.ENVI('darkavg');
           obj.ENVI('whiteavg');
           %obj.ENVI('reflectavg');
           obj.ENVI('bin');
           obj.ENVI('whitebin');
           obj.ENVI('darkbin');
           obj.ENVI('flatfield');
           %obj.ENVI('flatreflect');
           obj.ENVI('correct');
           obj.ENVI('darkwhite');
           %obj.ENVI('darkreflect');
           obj.ENVI('darksub');
           msgbox('Data Cubes Converted to ENVI')
        end
        function ENVI(obj, imgType)
           file = cell2mat(struct2cell(load(defaults.cubeLocation(obj.saveLocation, obj.title, imgType, '0'))));
           enviwrite(file, defaults.ENVILocation(obj.saveLocation, obj.title, imgType, '0'));
        end
        function n = rectanglePixelAvg(obj, minX, minY, maxX, maxY, img)
            binAmount = 1.0 / 2^obj.binNumber;
            x = minX * binAmount;
            y = minY * binAmount;
            average = double(0);
            while x <= maxX * binAmount
                while y <= maxY * binAmount
                    average = average + double(img(y, x));
                    y = y + 1;
                end
                y = minY;
                x = x + 1;
            end
            n = double(average / double((maxX * binAmount - minX *binAmount + 1) * (maxY * binAmount - minY * binAmount + 1)));
        end
    end
end
