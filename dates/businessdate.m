function bd = businessdate(date,dirFlag,city)
%bd = businessdate(date,dirFlag,city) returns the scalar,vector or matrix
%of the next or previous business days(s) depending on the city.

if nargin < 1
    error('businessdate:invalid date input');
end

if nargin < 2 || isempty(dirFlag)
    dirFlag = 1;
end

if (nargin < 3 || isempty(city)) || strcmpi(city,'shanghai')
    holidays = [736330,...
                736368,...
                736369,...
                736370,...
                736371,...
                736372,...
                736424,...
                736452,...
                736490,...
                736491,...
                736588,...
                736589,...
                736606,...
                736607,...
                736608,...
                736609,...
                736610,...
                736697,...
                736722,...
                736725,...
                736726,...
                736727,...
                736728,...
                736788,...
                736789,...
                736816,...
                736844,...
                736845,...
                736970,...
                736971,...
                736972,...
                736973,...
                736974];
end

if ischar(dirFlag)
    if ~(strcmpi(dirFlag,'modifiedfollow') || strcmpi(dirFlag,'follow') ||...
         strcmpi(dirFlag,'modifiedprevious') || strcmpi(dirFlag,'previous'))
            error('businessdate:invalid dirFlag string input');
    end
elseif isscalar(dirFlag)
    if ~(dirFlag == 1 || dirFlag == -1)
        error('businessdate:invalid dirFlag scalar input');
    end
else
    error('invalid dirFlag input datatype');
end

bd = busdate(date,dirFlag,holidays);


end