classdef ProfileListManager < handle & matlab.mixin.SetGet
    %PROFILELISTMANAGER Maintains a list of PackageFitDiffractionData objects.
    %   Only a single instance is allowed. To get the handle to the currently
    %   existing ProfileListManager instance, call the static method
    %   ProfileListManager.getInstance.
   properties
       
       DataPath = [];
       
       OutputPath = ['FitOutputs' filesep];
       
       FitResults % each profile results in a cell
       
   end
   
   properties (Dependent)
       ActiveProfile
       
       FileNames 
       
       NumFiles
       
       Min2T
       
       Max2T
       
       BackgroundPoints
       
       NumPeaks
       
       FcnNames
       
       PeakPositions
       
       FitInitial
   end
   
   properties (Dependent, Hidden)
       xrd
       
       CuKa
       
       KAlpha1=1.54000;
       
       KAlpha2 = 1.544426; 
   end
   
   properties (SetObservable)
       Status % has priority over the GUIController status
   end
   
   properties (Hidden)
       ext % file type for this dataset
       FullTwoThetaRange
%        FullIntensityData
       Temperature
       kBeta
       RKa1Ka2
       
       Validator 
       
       ValidFunctions = {'Gaussian', 'Lorentzian', 'Pearson VII', 'Pseudo-Voigt', 'Asymmetric Pearson VII'};
       
       xrdContainer
       
       initialXRD_
       
       Writer
              
      CurrentProfileNumber_ = 0;
      
   end
   
   
   methods (Access = private)
       function this = ProfileListManager()
       this.xrdContainer = [];
       end
   end
   
   methods 
       function set.Min2T(this, min2t)
       this.xrd.Min2T = this.Validator.min2T(min2t);
       this.xrd.setBackgroundPoints(this.Validator.backgroundPoints);
       end
       
       function min2t = get.Min2T(this)
       min2t = this.xrd.Min2T;
       end
       
       function set.Max2T(this, max2t)
       this.xrd.Max2T = this.Validator.max2T(max2t);
       this.xrd.setBackgroundPoints(this.Validator.backgroundPoints);
       end
       
       function max2t = get.Max2T(this)
       max2t = this.xrd.Max2T;
       end
       
       function set.BackgroundPoints(this, points)
       validpoints = this.Validator.backgroundPoints(points);
       this.xrd.setBackgroundPoints(validpoints);
       end
       
       function points = get.BackgroundPoints(this)
       points = this.Validator.backgroundPoints();
       end
       
       function set.NumPeaks(this, num)
       num = this.Validator.numberOfPeaks(num);
       oldfcns = this.FcnNames;
       newfcns = cell(1,num);
       for i=1:num
           if i <= length(oldfcns) && ~isempty(oldfcns{i})
               newfcns{i} = oldfcns{i};
           else
               break
           end
       end
       this.xrd.setFunctions(newfcns);
       end
       
       function num = get.NumPeaks(this)
       % Returns the number of unique peaks
       peakcoeffs = find(contains(this.xrd.getCoeffs, 'x'));
       num = length(peakcoeffs);
       end
       
       function set.FcnNames(this, fcns)
       % fcns is a string cell array
       this.xrd.setFunctions(fcns);
       end
       
       function fcns = get.FcnNames(this)
       % Returns a string cell array of the function names
       fcns = this.xrd.getFunctionNames;
       end
       
       function set.PeakPositions(this, pos)
       this.xrd.PeakPositions = this.Validator.peakPositions(pos);
       end
       
       function pos = get.PeakPositions(this)
       pos = this.Validator.peakPositions;
       end
       
       function set.FitInitial(this, fitbounds)
       % If FitInitial is set to 'default', it fills all the empty coefficicient values with default
       % values but doesn't replace any existing ones.
       %
       % If FitInitial is set to 'new', it overwrites all empty fit initial values with the default
       % coefficient values.
       if ischar(fitbounds)
           defaultBounds = this.xrd.getDefaultBounds;
           if strcmpi(fitbounds, 'default')
               this.xrd.FitInitial = this.Validator.defaultFitBoundsPreserved(defaultBounds);
           elseif strcmpi(fitbounds, 'new')
               this.xrd.FitInitial = defaultBounds;
               this.xrd.FitInitial = this.Validator.verifiedFitBounds(defaultBounds);
           end
       else
           this.xrd.FitInitial = this.Validator.verifiedFitBounds(fitbounds);
       end
       end
       
       function vals = get.FitInitial(this)
       vals = this.xrd.FitInitial;
       end
       
   end
   
   methods
       function isNew = newXRD(this, path, filename)
       isNew = false;
        try
    PrefFile=fopen('Preference File.txt','r');
    this.DataPath=fscanf(PrefFile,'%c');
    this.DataPath(end)=[]; % method above adds a white space at the last character that messes with import
    fclose(PrefFile);
        catch
        end
       
       
       if nargin < 2
           [data, filename, path] = utils.fileutils.newDataSet(this.DataPath);
           if isempty(data)
               return
           end
       else % if xrd was already created, just save as the new xrd
           data = utils.fileutils.newDataSet(path,filename);
       end
       isNew = true;
       this.reset();
       this.initialXRD_ = PackageFitDiffractionData(data, filename);
       this.initialXRD_.DataPath = path;
       this.ext = data(1).ext;
       
       xrdItem = this.initialXRD_;
       this.FullTwoThetaRange = xrdItem.getTwoTheta;
       this.DataPath = xrdItem.DataPath;
       xrdItem.OutputPath = [xrdItem.DataPath 'FitOutputs' filesep];
       xrdItem.MonoWavelength=data.Wavelength;
       this.OutputPath = xrdItem.OutputPath;
       this.Writer = ui.FileWriter(this);
       this.xrdContainer = this.initialXRD_;
       
       if strcmpi(this.ext, '.xrdml')
           this.Temperature = {data.Temperature};
           this.KAlpha1 = data(1).KAlpha1;
           this.KAlpha2 = data(1).KAlpha2;
           this.kBeta = data(1).kBeta;
           this.RKa1Ka2 = data(1).RKa1Ka2;
           this.CuKa = true;
       else
           this.CuKa = false;
       end
       
       this.Validator = utils.Validator(this, this.xrd);
       end
       
       function files = get.FileNames(this)
       if isempty(this.xrd)
           files = '';
           return
       end
       files = this.xrd.getFileNames;
       end
       
       function numfiles = get.NumFiles(this)
       if isempty(this.xrd)
           numfiles = 0;
           return
       end
       numfiles = length(this.xrd.getFileNames);
       end
       
       function set.CuKa(this, value)
       if ~isempty(this.xrd)
           this.xrd.CuKa = value;
       end
       end
       
       function val = get.CuKa(this)
       val = [];
       if isempty(this.xrd)
           return
       end
       val = this.xrd.CuKa;
       end
       
       function set.KAlpha1(this, value)
       try
           this.xrd.KAlpha1 = value;
       catch
       end
       end
       
       function val = get.KAlpha1(this)
       val = [];
       if ~isempty(this.xrd)
           val = this.xrd.KAlpha1;
       end
       end
       
       function set.KAlpha2(this, value)
       try
           if ~isempty(this.xrd)
               this.xrd.KAlpha2 = value;
           end
       catch
       end
       end
       
       function val = get.KAlpha2(this)
       val = [];
       try
           if ~isempty(this.xrd)
               val = this.xrd.KAlpha2;
           end
       catch
       end
       end
       
       function set.ActiveProfile(this, number)
       if number < 1
           this.CurrentProfileNumber_ = 1;
       elseif number > this.getNumProfiles
           this.CurrentProfileNumber_ = this.getNumProfiles;
       else
           this.CurrentProfileNumber_ = number;
       end
       end
       
       function number = get.ActiveProfile(this)
       number = 1;
       end
       
       function this = reset(this)
       if isempty(this.initialXRD_)
           this.xrdContainer = [];
           this.CurrentProfileNumber_ = 0;
           this.Writer = [];
       else
%            this.xrdContainer = copy(this.initialXRD_);
this.FitResults=[];
this.xrd.FitInitial=[];
this.xrd.PeakPositions(1:end)=0;
           this.Writer = ui.FileWriter(this);
       end
       end
       
       function output = hasData(this)
        if isempty(this.xrdContainer)
            output = false;
        else
            output = true;
        end
       end 
       
       function a = hasFit(this)
        if isempty(this.FitResults) || isempty(this.FitResults{1})
            a = false;
        else
            a = true;
        end
        end
       
       
       function num = getCurrentProfileNumber(this)
       num = this.CurrentProfileNumber_;
       end
       
       function value = getNumProfiles(this)
       %GETNUMPROFILES Returns the total number of profiles.
       if isempty(this.xrdContainer)
           value = 0;
       else
           value = length(this.xrdContainer);
       end
       end
       
       
       function this = exportProfileParametersFile(this)
       % Assuming there is already a fit
       this.Writer.saveAsFitParameters(this.getProfileResult);
       end
        
       function this = importProfileParametersFile(this, filename)
       %IMPORTPROFILEPARAMETERSFILE(PATH, FILENAME) Reads a parameters file into
       %    the current profile.
       fid = fopen(filename, 'r');
       if fid == -1
           errordlg('Parameter file could not be opened.')
       end
       while ~feof(fid)
          line = fgetl(fid);
          a = strsplit(line,' ');
          switch a{1}
              case '2ThetaRange:'
                  min = str2double(a{2});
                  max = str2double(a{3});
              case 'BackgroundModel:'
                  model = a{2};
              case 'PolynomialOrder:'
                  polyorder = str2double(a{2});
              case 'BackgroundPoints:'
                bkgdpoints = str2double(a(2:end));
              case 'Cu-KAlpha1:'
                  if ~isequal(a{2}, 'n/a')
                      ka1 = str2double(a{2});
                  else
                      ka1 = [];
                  end
              case 'Cu-KAlpha2:'
                  if ~isequal(a{2}, 'n/a')
                      ka2 = str2double(a{2});
                  else
                      ka2 = [];
                  end
              case 'FitFunction(s):'
                line = fgetl(fid);
                fxn = strsplit(line, '; ');
                if isempty(fxn{end})
                    fxn(end) = [];
                end
              case 'PeakPosition(s):'
                peakpos = str2double(a(2:end));
                peakpos = peakpos(1:length(fxn));
              case 'Constraints:'
                  this.xrd.unconstrain('Nxfwm');
                  str = a(2:end);
            case '=='
                break
              otherwise
          end
       end
       this.xrd.Min2T = min;
       this.xrd.Max2T = max;
       if ~isempty(ka2)
           this.xrd.KAlpha2 = ka2;
           this.xrd.CuKa = true;
       end
        if ~isempty(ka1)
         this.xrd.KAlpha1 = ka1;
       end
       this.xrd.setBackgroundModel(model);
       this.xrd.setBackgroundOrder(polyorder);
       this.xrd.setBackgroundPoints(bkgdpoints);
       this.xrd.setFunctions(fxn);
       this.xrd.PeakPositions = peakpos;
       for i=1:length(str)
           cons = strtok(str{i}, '{''''}');
           this.xrd.constrain(cons, i);
       end
       % Read coefficient names
       line  = fgetl(fid);
       coeff = textscan(line, '%s');
       coeff = coeff{1}';
       if ~isequal(coeff, this.xrd.getCoeffs)
           error('Coefficients do not match')
       end
       % Read SP values
       line  = fgetl(fid);
       start    = textscan(line,'%s');
       start    = start{1}';
       init.start    = str2double(start(2:end));
       % Read UB values
       line  = fgetl(fid);
       lower    = textscan(line,'%s');
       lower    = lower{1}';
       init.lower    = str2double(lower(2:end));
       % Read LB values
       line  = fgetl(fid);
       ub    = textscan(line,'%s');
       ub    = ub{1}';
       init.upper    = str2double(ub(2:end));
       this.xrd.FitInitial = init;
       fclose(fid);
       end
       
       function results = getProfileResult(this, profnum)
       results = this.FitResults{1};
       end
       
       function fitresults = fitDataSet(this, prfn)
        % Fits the entire dataset for the current profile and saves it as a cell array of FitResults.
        if nargin < 2
            prfn = this.getCurrentProfileNumber;
        end
        fitresults = cell(1, this.NumFiles);
        msg = LiprasDialog.fittingDataSet;
        for i=1:this.NumFiles
            this.Status = ['Fitting dataset ' num2str(i) ' of ' num2str(this.NumFiles) '...'];
            try
                % stop the fit if the user closes the msgbox
%                 if ~isvalid(msg)
%                     this.Status = 'Stopped fitting dataset.';
%                     fitresults = [];
%                     return
%                 end
                fitresults{i} = model.FitResults(this, i);
            catch exception
                delete(msg)
                exception.getReport
                rethrow(exception)
            end
        end
        delete(msg);
        this.FitResults{prfn} = fitresults;
        this.Writer.printFitOutputs(fitresults);
        end
   end
        
   methods
       function value = get.xrd(this)
       value = [];
       try
           value = this.xrdContainer(1);
       catch
       end
       end
       
       function set.xrd(this, xrd)
       this.xrdContainer(this.CurrentProfileNumber_) = xrd;
       end
       
       function xdata = dspace(this, twotheta)
        xdata = this.KAlpha1 ./ (2*sind(twotheta./2));
       end
       
       function xdata = twotheta(this, dspace)
       xdata = 2*asind(this.KAlpha1 ./ (2*dspace));
       end
   end
   
   methods (Static)
       
       function singleObj = getInstance(obj)
       persistent localObj;
       if nargin > 0
           localObj = obj;
       elseif isempty(localObj) || ~isvalid(localObj)
           localObj = model.ProfileListManager(); 
       end
       singleObj = localObj;
       end
   end
   
   
end