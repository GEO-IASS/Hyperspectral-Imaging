classdef camera < handle
    properties (Access = private)
        exposure
        power
        cam
        gain
    end
    methods
        function obj = camera()
            obj.gain = 0;
            obj.exposure = 900;
            obj.power = 0;
            obj.cam = 0;
        end
        function connect(obj)
            % Camera NB to work with.
            obj.cam=1;							
            % Open camera to work with.
            LucamCameraOpen(obj.cam);					
            % Set to 16-bit
            LucamSet16BitCapture(true,obj.cam); 
            % Get format settings
            ff=LucamGetFormat(obj.cam); 
            % Set format for 2x2 binning
            ff.xBinSub=2; 
            ff.yBinSub=2;
            ff.xFlags=1;
            ff.yFlags=1;
            LucamSetFormat(ff,obj.cam)
            % Open preview window
            LucamShowPreview(obj.cam) 
            pause(defaults.shortdelay());
            obj.power = 1;
        end
        function disconnect(obj)
           LucamHidePreview(obj.cam)
           LucamCameraClose(obj.cam);
           obj.power = 0;
        end
        function setGain(obj, gain)
            if obj.power
                LucamSetGain(gain, obj.cam); 
                pause(defaults.shortdelay());
                obj.gain = gain;
            else
                errordlg('Devices Not Connected')
            end
        end
        function setExposure(obj, exposure)
            if obj.power
                LucamSetExposure(exposure, obj.cam); 
                pause(defaults.shortdelay());
                obj.exposure = exposure;
            else
                errordlg('Devices Not Connected')
            end
        end
        function gain = getGain(obj)
            gain = obj.gain;
        end
        function exposure = getExposure(obj)
            exposure = obj.exposure;
        end
        function test = isConnected(obj)
            test = obj.power;
        end
        function img = takePicture(obj)
            if obj.power
                img = LucamCaptureRawFrame(obj.cam);
                pause(defaults.longdelay());
                pause(defaults.longdelay());
            else
                errordlg('Camera Not Connected')
            end
        end
        function value = getCam(obj)
            value = obj.cam;
        end
        function autoSetExposure(obj)
            [lw,lh]=LucamGetFrameSize(obj.cam);
            LucamOneShotAutoExposure(lh, lw, 0, 0, 127, obj.cam);
            obj.exposure = LucamGetExposure(obj.cam);
        end
    end
    methods (Static)
        function portErr()
           x = instrfind;
           delete(x);
        end
    end
end