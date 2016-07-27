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