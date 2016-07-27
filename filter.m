classdef filter < handle
        properties (Access = private)
        wavelength
        power
        serial
    end
    methods
        function obj = filter()
            obj.power = 0;
            obj.serial = 0;
            obj.wavelength = 550;
        end
        function connect(obj)
            obj.serial = serial('COM3');  %#ok<CPROP>
            % Set communication string to end on ASCII 13
            set(obj.serial, 'Terminator', 'CR'); 
            % Baud rate for VF filter
            set(obj.serial, 'BaudRate', 115200); 
            % Rest of communication parameters are standard
            set(obj.serial, 'StopBits', 1);
            set(obj.serial, 'DataBits', 8);
            set(obj.serial, 'Parity', 'none');
            fopen(obj.serial);
            echo off;
            obj.power = 1;
        end
        function disconnect(obj)
           fclose(obj.serial);
           delete(obj.serial);
           obj.serial = 0;
           obj.power = 0;
        end
        function setWavelength(obj, wavelength)
            if obj.power
                fprintf(obj.serial,['W ',int2str(wavelength)]); 
                pause(defaults.shortdelay())
                obj.wavelength = wavelength;
            else
                errordlg('Devices Not Connected')
            end
        end
        function wavelength = getWavelength(obj)
            wavelength = obj.wavelength;
        end
        function test = isConnected(obj)
            test = obj.power;
        end
    end
end