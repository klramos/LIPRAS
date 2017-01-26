classdef FitFunctionInterface < handle
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties 
       CoeffValues
    end
    
    properties (Dependent)
       PeakPosition
       
    end
    
    properties (Access = protected)
        Primitive
        
    end
    
    
    properties (Abstract)
        % Function name
        Name
        
        % Cell array of coefficient names, without trailing peak number
        CoeffNames

        % Fit function peak number
        ID
                
    end
    
    properties (Hidden, Constant)
       DEFAULT_OFFSET_X = 0.05;
       
       DEFAULT_MULTIPLIER_N = 5;
       
       DEFAULT_MULTIPLIER_F = 2;
       
       DEFAULT_VALUE_W = 0.5;
       
       DEFAULT_UPPER_W = 1;
       
       DEFAULT_VALUE_M = 2;
       
       DEFAULT_UPPER_M = 20;
    end
    
    properties (Dependent)

        % Cell array of constrained coefficients
        ConstrainedCoeffs
        
    end
    
    properties (Hidden)
        RawData
        
        PeakPosition_
        
        ConstrainedLogical = false(1,5);
        
        ConstrainedCoeffs_
        
    end
    
    methods
        function this = FitFunctionInterface(id, constraints)
        if nargin < 1
            id = 1;
        end
        
        if nargin < 2
            constraints = '';
        end
        
        this.ID = id;
        this = this.constrain(constraints);
        this.Primitive = this;
        end
        
        function this = constrain(this, coeffs)
        %CONSTRAIN(COEFFS) 
        %
        %   COEFFS a string
        
        if isempty(coeffs)
            return
        end
        
        import utils.*
        
        if contains(lower(coeffs), 'n')
            this.ConstrainedLogical(1) = true;
        end
            
        if contains(lower(coeffs), 'x')
            this.ConstrainedLogical(2) = true;
        end
        
        if contains(lower(coeffs), 'f')
            this.ConstrainedLogical(3) = true;
        end
        
        if contains(lower(coeffs), 'w') && contains(this.Name, 'Pseudo')
            this.ConstrainedLogical(4) = true;
        end
        
        if contains(lower(coeffs), 'm') && contains(this.Name, 'Pearson')
            this.ConstrainedLogical(5) = true;
        end

        end
        
        function this = unconstrain(this, coeff)
         if isempty(coeff)
            return
        end
        
        if contains(lower(coeff), 'n')
            this.ConstrainedLogical(1) = false;
        end
            
        if contains(lower(coeff), 'x')
            this.ConstrainedLogical(2) = false;
        end
        
        if contains(lower(coeff), 'f')
            this.ConstrainedLogical(3) = false;
        end
        
        if contains(lower(coeff), 'w')
            this.ConstrainedLogical(4) = false;
        end
        
        if contains(lower(coeff), 'm')
            this.ConstrainedLogical(5) = false;
        end
        end
    end
    
    
    
    methods (Abstract)
        str = getEqnStr(this)
        % Returns a string of the equation
        
    end
    
    methods
        
        function value = get.Primitive(this)
        value = this;
        end
        
        function result = getUnconstrainedCoeffs(this)
        coeffs = this.getCoeffs;
        
        for i=1:length(coeffs)
            coeffs{i} = coeffs{i}(1);
        end
        
        idx = zeros(1, length(this.ConstrainedCoeffs));
        
        for i=1:length(this.ConstrainedCoeffs)
            idx(i) = find(strcmpi(this.ConstrainedCoeffs{i}, coeffs), 1);
        end
        
        result = this.getCoeffs;
        result(idx) = [];
        end
        
        function output = calculateFit(this, x, fitinitial)
        %
        %
        %
        %FITINITIAL - The initial points to use for the coefficients. Each
        %   member in the numeric array corresponds to the coefficients in
        %   this.getCoeffs, respectively.
                
        output = this.calculate_(x, fitinitial);
        end
        
        function output = getDefaultUnconstrainedValues(this, data)
        % Returns a structure with fields 'initial', 'lower', 'upper', and
        %   'coeff' all with the same length. The 'coeff' field contains the
        %   list of coefficients in order as the initial, lower, and upper
        %   fields.
        
        init = this.getDefaultInitialValues(data);
        low = this.getDefaultLowerBounds(data);
        up = this.getDefaultUpperBounds(data);
        unconstrained = this.getUnConstrainedCoeffs;
        
        initial = []; lower = []; upper = []; 
        
        for i=1:length(unconstrained)
           ch = unconstrained{i}(1);
           initial = [initial init.(ch)];
           lower = [lower low.(ch)];
           upper = [upper up.(ch)];
        end
        
        output.initial = initial;
        output.lower = lower;
        output.upper = upper;
        output.coeff = unconstrained;
        end
        
        function output = getDefaultConstrainedValues(this, data)
        % Returns a structure with fields 'initial', 'lower', 'upper', and
        %   'coeff' all with the same length. The 'coeff' field contains the
        %   list of coefficients in order as the initial, lower, and upper
        %   fields.
        
        if nargin < 2
            data = this.RawData;
        end
        
        init = this.getDefaultInitialValues(data);
        low = this.getDefaultLowerBounds(data);
        up = this.getDefaultUpperBounds(data);
        constrained = this.getConstrainedCoeffs;
        
        initial = []; lower = []; upper = []; 
        
        for i=1:length(constrained)
           ch = constrained{i}(1);
           initial = [initial init.(ch)];
           lower = [lower low.(ch)];
           upper = [upper up.(ch)];
        end
        
        output.initial = initial;
        output.lower = lower;
        output.upper = upper;
        output.coeff = constrained;
        
        this.RawData = data;
        end

        
        function set.ConstrainedCoeffs(this, value)
        constraints = this.ConstrainedLogical;
        
        if isnumeric(value)
            this.ConstrainedLogical(value) = ~constraints(value);
            
        elseif ischar(value) || iscell(value)
            constraints = this.constrain(value);
            
        elseif ~ischar(value) || ~islogical(value)
            keyboard
        else
            keyboard
        end
        
        this.ConstrainedLogical = constraints;
        
        end
        
        function set.PeakPosition(this, value)
        this.setPeakPosition(value);
        end
        
        function value = get.PeakPosition(this)
        value = this.getPeakPosition();
        end
        
        function result = get.ConstrainedCoeffs(this)
        constraints = this.ConstrainedLogical;
            
        result = {};
        
        if constraints(1)
            result = [result, 'N'];
        end
        
        if constraints(2)
            result = [result, 'x'];
        end
        
        if constraints(3)
            result = [result, 'f'];
        end
        
        if constraints(4) 
            result = [result, 'w'];
        end
        
        if constraints(5)
            result = [result, 'm'];
        end
        end
        
        function result = getCoeffs(this)
        constraints = this.ConstrainedLogical;
        unconstrained = [];
        
        if ~constraints(1)
            unconstrained = [unconstrained {[this.CoeffNames{1} num2str(this.ID)]}];
        end
            
        if ~constraints(2)
            unconstrained = [unconstrained {[this.CoeffNames{2} num2str(this.ID)]}];
        end
        
        if ~constraints(3)
            unconstrained = [unconstrained {[this.CoeffNames{3} num2str(this.ID)]}];
        end
        
        if ~constraints(4) && contains(this.Name, 'Pseudo')
            unconstrained = [unconstrained {[this.CoeffNames{4} num2str(this.ID)]}];
        end
        
        if ~constraints(5) && contains(this.Name, 'Pearson VII')
            unconstrained = [unconstrained {[this.CoeffNames{4} num2str(this.ID)]}];
        end
        
        result = [this.ConstrainedCoeffs, unconstrained];
        end
        
        function output = getConstrainedCoeffs(this)
        output = this.ConstrainedCoeffs;
        end
        
        function result = getDefaultInitialValues(this, data)
        %GETDEFAULTINITIALVALUES
        %
        %DATA - Numeric array of data to fit, assuming the background fit was
        %   already subtracted.
        %
        %PEAKPOSITION - Two theta position of the estimated peak
        import utils.*
        import model.fitcomponents.*
        
        xdata = data(1,:);
        ydata = data(2,:);
        
        result.x = this.PeakPosition;
        
        xlow = this.PeakPosition - FitFunctionInterface.DEFAULT_OFFSET_X;
        if xlow < xdata(1)
            xlow = xdata(1);
        end
        xlowi_ = findIndex(xdata, xlow);
        xup = this.PeakPosition + FitFunctionInterface.DEFAULT_OFFSET_X;
        if xup > xdata(end)
            xup = xdata(end);
        end
        xupi_ = findIndex(xdata, xup);
        
        
        result.N = trapz(xdata(xlowi_:xupi_), ydata(xlowi_:xupi_));
        
        result.f = 2*result.N / max(ydata);
        
        result.w = FitFunctionInterface.DEFAULT_VALUE_W;
        
        result.m = FitFunctionInterface.DEFAULT_VALUE_M;
        end
        
        function result = getDefaultLowerBounds(this, ~)
        import model.fitcomponents.*
        import utils.*
        
        result.x = this.PeakPosition - FitFunctionInterface.DEFAULT_OFFSET_X;
        
        result.N = 0;
        
        result.f = 0;
        
        result.w = 0;
        
        result.m = 0;
        
        end
        
        function result = getDefaultUpperBounds(this, data)
        import model.fitcomponents.*
        import utils.*
        
        initial = this.getDefaultInitialValues(data);
        
        result.x = this.PeakPosition + FitFunctionInterface.DEFAULT_OFFSET_X;
        
        result.N = initial.N * FitFunctionInterface.DEFAULT_MULTIPLIER_N;
        
        result.f = initial.f * FitFunctionInterface.DEFAULT_MULTIPLIER_F;
        
        result.w = FitFunctionInterface.DEFAULT_UPPER_W;
        
        result.m = FitFunctionInterface.DEFAULT_UPPER_M;
        
        end
        
        function result = isAsymmetric(this)
        if contains(this.Name, 'Asymmetric')
            result = true;
        else
            result = false;
        end
        end
        
        function result = isNConstrained(this)
        result = this.ConstrainedLogical(1);
        end
        
        function result = isXConstrained(this)
        result = this.ConstrainedLogical(2);
        end
        
        function result = isFConstrained(this)
        result = this.ConstrainedLogical(3);
        end
        
        function result = isWConstrained(this)
        result = this.ConstrainedLogical(4);
        end
        
        function result = isMConstrained(this)
        result = this.ConstrainedLogical(5);
        end
        
    end
    
    
    methods (Access = protected)
        function this = setPeakPosition(this, value)
        this.PeakPosition_ = value;
        end
        
        function value = getPeakPosition(this)
        value = this.PeakPosition_;
        end
        
        
    end
    
    methods (Abstract, Access = protected)
       output = calculate_(this, xdata, coeffvals);
        
    end
    
end
