classdef FitFunctionInterface < handle
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties 
       CoeffValues
    end
    
    properties (Dependent)
       PeakPosition
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
        
        CuKa = false;
        
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
        import utils.contains
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
        str = getEqnStr(this, coeff)
        %GETEQNSTR returns the equation of the current function as a string. The variables used in 
        %   the equation are numbered with respect to the function order. If COEFF isn't specified,
        %   the default coefficients are used.
        
    end
    
    methods
                
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
        
        function output = calculateFit(this, xdata, fitinitial)
        % calculateFit  Returns the calculated array of values for the x values in xdata using the
        %    coefficient values of fitinitial.
        %
        %FITINITIAL - The initial points to use for the coefficients. Each
        %   member in the numeric array corresponds to the coefficients in
        %   this.getCoeffs, respectively.
        output = this.calculate_(xdata, fitinitial);
        end
        
        function output = getDefaultUnconstrainedValues(this, data, peakpos)
        % Returns a structure with fields 'initial', 'lower', 'upper', and
        %   'coeff' all with the same length. The 'coeff' field contains the
        %   list of coefficients in order as the initial, lower, and upper
        %   fields.
        init = this.getDefaultInitialValues(data, peakpos);
        low = this.getDefaultLowerBounds(data, peakpos);
        up = this.getDefaultUpperBounds(data, peakpos);
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
        
        function output = getDefaultConstrainedValues(this, data, peakpos)
        % Returns a structure with fields 'initial', 'lower', 'upper', and
        %   'coeff' all with the same length. The 'coeff' field contains the
        %   list of coefficients in order as the initial, lower, and upper
        %   fields. 
        init = this.getDefaultInitialValues(data, peakpos);
        low = this.getDefaultLowerBounds(data, peakpos);
        up = this.getDefaultUpperBounds(data, peakpos);
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
        this.PeakPosition_ = value;
        end
        
        function value = get.PeakPosition(this)
        value = this.PeakPosition_();
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
        %GETCOEFFS returns a cell array of strings with the coefficients to use in the fit equation.
        import utils.contains
        constraints = this.ConstrainedLogical;
        num = num2str(this.ID);
        unconstrained = cell(1, length(this.CoeffNames)); i=1;
        if ~constraints(1)
            unconstrained{i} = [this.CoeffNames{1} num];
            i=i+1;
        end    
        if ~constraints(2)
            unconstrained{i} = [this.CoeffNames{2} num];
            i=i+1;        
        end
        if ~constraints(3)
            unconstrained{i} = [this.CoeffNames{3} num];
            i=i+1;
        end
        if ~constraints(4) && contains(this.Name, 'Pseudo')
            unconstrained{i} = [this.CoeffNames{4} num];
            i=i+1;
        elseif ~constraints(5) && contains(this.Name, 'Pearson VII')
            unconstrained{i} = [this.CoeffNames{4} num];
            i=i+1;
        end
        if i <= length(unconstrained)
            unconstrained(i:end) = [];
        end
        result = [this.ConstrainedCoeffs, unconstrained];
        end
        
        function output = getConstrainedCoeffs(this)
        output = this.ConstrainedCoeffs;
        end
        
        function result = getDefaultInitialValues(this, data, peakpos)
        %GETDEFAULTINITIALVALUES
        %
        %DATA - Numeric array of data to fit, assuming the background fit was
        %   already subtracted.
        %
        %PEAKPOSITION - Two theta position of the estimated peak
        import utils.*
        import model.fit.*
        xdata = data(1,:);
        ydata = data(2,:);
        xoffset = (xdata(end) - xdata(1)) ./ 10;
        result.x = peakpos;
        xlow = peakpos - xoffset;
        if xlow < xdata(1)
            xlow = xdata(1);
        end
        xlowi_ = findIndex(xdata, xlow);
        xup = result.x + xoffset;
        if xup > xdata(end)
            xup = xdata(end);
        end
        xupi_ = findIndex(xdata, xup);
        try
            result.N = trapz(xdata(xlowi_:xupi_), ydata(xlowi_:xupi_));
        catch
            result.N = trapz(xdata, ydata) / 2;
        end
        
        
        result.f = result.N / max(ydata(xlowi_:xupi_));
        result.w = FitFunctionInterface.DEFAULT_VALUE_W;
        result.m = FitFunctionInterface.DEFAULT_VALUE_M;
        end
        
        function result = getDefaultLowerBounds(this, data, peakpos)
        import model.fit.*
        import utils.*
        initial = this.getDefaultInitialValues(data, peakpos);
        
        xoffset = (data(1,end) - data(1,1)) ./ 10;

        result.x = peakpos - xoffset;
        result.N = 0;
        result.f = 0.01;
        result.w = 0;
        result.m = 0.5;
        end
        
        function result = getDefaultUpperBounds(this, data, peakpos)
        import model.fit.*
        import utils.*
        initial = this.getDefaultInitialValues(data, peakpos);
        xoffset = (data(1,end) - data(1,1)) ./ 10;
        result.x = peakpos + xoffset;
        result.N = initial.N * 2;
        result.f = initial.f * 2;
        result.w = 1;
        result.m = FitFunctionInterface.DEFAULT_VALUE_M * 10;
        end
        
        function result = isAsymmetric(this)
        if utils.contains(this.Name, 'Asymmetric')
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
        
        function lineObj = plot(this, xdata, coeffvals)
        ydata = this.calculateFit(xdata, coeffvals);
        lineObj = line(xdata, ydata, 'visible', 'off', 'Tag', ['f' num2str(this.ID)], ...
            'DisplayName', ['(' num2str(this.ID) ') ' this.Name]);
        setappdata(lineObj, 'xdata', xdata);
        setappdata(lineObj, 'ydata', ydata);
        end
        
        function coefficient = coeff(this, letter)
        %coeff Returns the coefficient starting with 'letter' used for the equation in the fit.
        %   'letter' must be either: {'N', 'x', 'f', 'w', 'm'}.
        coeffs = this.getCoeffs;
        idx = utils.contains(coeffs, letter);
        coefficient = coeffs(idx);
        if length(coefficient) == 1
            coefficient = coefficient{1};
        end
        end
    end
    
    methods (Abstract, Access = protected)
       output = calculate_(this, xdata, coeffvals);
    end
    
end

