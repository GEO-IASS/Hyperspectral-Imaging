classdef defaults
	methods (Static)
		function value = longdelay()
			value = 2;
		end
		function value = shortdelay()
			value = 1;
		end
		function file = defaultLocation(location, title, setType, wavelength, setNum)
            file = [location, title, '-', setType, '-', ...
                wavelength, '-', setNum, '.tif'];
        end
        function file = cubeLocation(location, title, setType, setNum)
            file = [location, title, '-', setType, '-', setNum, '.mat'];
        end
        function value = getSimpleGcurve()
            % Set default gain curve
              value = [30.0 28.0 24.0 24.0 24.0 10.0 8.0 6.0 4.0 ...
              3.0 2.0 1.8 1.6 1.4 1.2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
        end
        function value = getSimpleEcurve()
            %Set default exposure curve in ms
            value=[1500 1500 1500 1500 1500 1500 900 800 700 600 ...
            500 400 300 200 150 150 150 150 150 150 150 150 150 150 150 ...
            150 150 150 150 150 150 150 150];
%             value=[1000 1000 1000 1000 1000 600 600 600 600 200 ...
%             200 200 200 200 100 100 100 100 100 100 100 100 100 100 100 ...
%             100 100 100 100 100 100 100 100];
        end
        function cube = loadCube(location, title, setType, setNum)
            cube = cell2mat(struct2cell(load(defaults.cubeLocation(location, title, setType, int2str(setNum)))));
        end
        function file = ENVILocation(location, title, setType, setNum)
            file = [location, title, '-', setType, '-', setNum];
        end
        function value = flatConstant()
            value = 1;
        end
        function value = stdReflectance()
           value = 0.99; 
        end
        function answer = closestFactor(totalIntervalSize, appxFactor)
            answer = 0;
            counter = 1;
            while answer == 0
                if mod(totalIntervalSize, appxFactor + counter) == 0
                    answer = appxFactor + counter;
                elseif mod(totalIntervalSize, appxFactor - counter) == 0
                    answer = appxFactor - counter;
                else
                    counter = counter + 1;
                end
            end
        end
        function value = contrastPrecision()
            value = 0.1;
        end
	end
end