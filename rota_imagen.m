function varargout = imrotate(varargin)
%IMROTATE Rotate image.
%   B = IMROTATE(A,ANGLE) rotates image A by ANGLE degrees in a 
%   counterclockwise direction around its center point. To rotate the image
%   clockwise, specify a negative value for ANGLE. IMROTATE makes the output
%   image B large enough to contain the entire rotated image. IMROTATE uses
%   nearest neighbor interpolation, setting the values of pixels in B that 
%   are outside the rotated image to 0 (zero).
%
%   B = IMROTATE(A,ANGLE,METHOD) rotates image A, using the interpolation
%   method specified by METHOD. METHOD is a string that can have one of the
%   following values. The default value is enclosed in braces ({}).
%
%        {'nearest'}  Nearest neighbor interpolation
%
%        'bilinear'   Bilinear interpolation
%
%        'bicubic'    Bicubic interpolation. Note: This interpolation
%                     method can produce pixel values outside the original
%                     range.
%
%   B = IMROTATE(A,ANGLE,METHOD,BBOX) rotates image A, where BBOX specifies 
%   the size of the output image B. BBOX is a text string that can have 
%   either of the following values. The default value is enclosed in braces
%   ({}).
%
%        {'loose'}    Make output image B large enough to contain the
%                     entire rotated image. B is generally larger than A.
%
%        'crop'       Make output image B the same size as the input image
%                     A, cropping the rotated image to fit. 
%
%   Class Support
%   -------------
%   The input image can be numeric or logical.  The output image is of the
%   same class as the input image.
%
%   Performance Note
%   ----------------
%   This function may take advantage of hardware optimization for datatypes
%   uint8, uint16, single, and double to run faster.
%
%   Example
%   -------
%        % This example brings image I into horizontal alignment by
%        % rotating the image by -1 degree.
%        
%        I = fitsread('solarspectra.fts');
%        I = mat2gray(I);
%        J = imrotate(I,-1,'bilinear','crop');
%        figure, imshow(I), figure, imshow(J)
%
%   See also IMCROP, IMRESIZE, IMTRANSFORM, TFORMARRAY.

%   Copyright 1992-2012 The MathWorks, Inc.
%   $Revision: 5.25.4.17 $  $Date: 2012/04/25 07:11:23 $

% Grandfathered:
%   Without output arguments, IMROTATE(...) displays the rotated
%   image in the current axis.  

[A,ang,method,bbox] = parse_inputs(varargin{:});

if (isempty(A)) 
    
    B = A; % No rotation needed    
    
else
    so = size(A);
    twod_size = so(1:2);
    
    if rem(ang,90) == 0
        % Catch and speed up 90 degree rotations
        
        % determine if angle is +- 90 degrees or 0,180 degrees.
        multiple_of_ninety = mod(floor(ang/90), 4);
        
        % initialize array of subscripts
        v = repmat({':'},[1 ndims(A)]);
        
        switch multiple_of_ninety
            
            case 0
                % 0 rotation;
                B = A;
                
            case {1,3}
                % +- 90 deg rotation
                
                thirdD = prod(so(3:end));
                A = reshape(A,[twod_size thirdD]);
                
                not_square = twod_size(1) ~= twod_size(2);
                if strcmpi(bbox, 'crop') && not_square
                    % center rotated image and preserve size
                    
                    imbegin = (max(twod_size) == so)*abs(diff(floor(twod_size/2)));
                    vec = 1:min(twod_size);
                    v(1) = {imbegin(1)+vec};
                    v(2) = {imbegin(2)+vec};
                    
                    new_size = [twod_size thirdD];
                    
                else
                    % don't preserve original size
                    new_size = [fliplr(twod_size) thirdD];
                end
                
                % pre-allocate array
                if islogical(A)
                    B = false(new_size);
                else
                    B = ones(new_size,class(A));
                end
                
                for k = 1:thirdD
                    B(v{1},v{2},k) = rot90(A(v{1},v{2},k),multiple_of_ninety);
                end
                
                B = reshape(B,[new_size(1) new_size(2) so(3:end)]);
                
            case 2
                % 180 rotation
                
                v(1) = {twod_size(1):-1:1};
                v(2) = {twod_size(2):-1:1};
                B = A(v{:});
        end
        
    else % Perform general rotation
        
        phi = ang*pi/180; % Convert to radians
        
        rotate = maketform('affine',[ cos(phi)  sin(phi)  0; ...
            -sin(phi)  cos(phi)  0; ...
            0       0       1 ]);
        
        [loA,hiA,loB,hiB,outputSize] = getOutputBound(rotate,twod_size,bbox);
        
        if useIPP(A)
            % The library routine has different edge behavior than our code.
            % This difference can be worked around with zero padding.
            A = padarray(A,[2 2],0,'both');
            
            if isreal(A)
                B = imrotatemex(A,ang,outputSize,method);
            else
                % If input is complex valued, call imrotatemex on real and
                % imaginary parts separately then combine results.
                B = complex(imrotatemex(real(A),ang,outputSize,method),...
                            imrotatemex(imag(A),ang,outputSize,method));
            end
            
        else % rotate using tformarray
            
            boxA = maketform('box',twod_size,loA,hiA);
            boxB = maketform('box',outputSize,loB,hiB);
            T = maketform('composite',[fliptform(boxB),rotate,boxA]);
            
            if strcmp(method,'bicubic')
                R = makeresampler('cubic','fill');
            elseif strcmp(method,'bilinear')
                R = makeresampler('linear','fill');
            else
                R = makeresampler('nearest','fill');
            end
            
            B = tformarray(A, T, R, [1 2], [1 2], outputSize, [], 0);
            
        end
    end
    
end


% Output
switch nargout,
case 0,
  % Need to set varargout{1} so ans gets populated even if user doesn't ask for output
  varargout{1} = B;  
case 1,
  varargout{1} = B;
case 3,
  error(message('images:removed:syntax','[R,G,B] = IMROTATE(RGB)','RGB2 = IMROTATE(RGB1)'))
otherwise,
  error(message('images:imrotate:tooManyOutputs'))
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Function: getOutputBound
%
function [loA,hiA,loB,hiB,outputSize] = getOutputBound(rotate,twod_size,bbox)

% Coordinates from center of A
hiA = (twod_size-1)/2;
loA = -hiA;
if strcmpi(bbox, 'loose')  % Determine limits for rotated image
    hiB = ceil(max(abs(tformfwd([loA(1) hiA(2); hiA(1) hiA(2)],rotate)))/2)*2;
    loB = -hiB;
    outputSize = hiB - loB + 1;
else % Cropped image
    hiB = hiA;
    loB = loA;
    outputSize = twod_size;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Function: useIPP
%
function TF = useIPP(A)
    
    % We enable acceleration for uint8, uint16, and single or double precision
    % floating point inputs.
    supportedType = isa(A,'uint8') || isa(A,'uint16') || isa(A,'float');
    TF =  ippl() && supportedType;
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Function: parse_inputs
%

function [A,ang,method,bbox] = parse_inputs(varargin)
% Outputs:  A       the input image
%           ang     the angle by which to rotate the input image
%           method  interpolation method (nearest,bilinear,bicubic)
%           bbox    bounding box option 'loose' or 'crop'

% Defaults:
method = 'n';
bbox = 'l';

narginchk(2,4)
switch nargin
case 2,             % imrotate(A,ang)        
  A = varargin{1};
  ang=varargin{2};
case 3,             % imrotate(A,ang,method) or
  A = varargin{1};  % imrotate(A,ang,box)
  ang=varargin{2};
  method=varargin{3};
case 4,             % imrotate(A,ang,method,box) 
  A = varargin{1};
  ang=varargin{2};
  method=varargin{3};
  bbox=varargin{4};
otherwise,
  error(message('images:imrotate:invalidInputs'))
end

% Check validity of the input parameters 
if ischar(method) && ischar(bbox),
  strings = {'nearest','bilinear','bicubic','crop','loose'};
  idx = strmatch(lower(method),strings);
  if isempty(idx),
    error(message('images:imrotate:unrecognizedInterpolationMethod', method))
  elseif length(idx)>1,
    error(message('images:imrotate:ambiguousInterpolationMethod', method))
  else
    if idx==4,bbox=strings{4};method=strings{1};
    elseif idx==5,bbox = strings{5};method=strings{1};
    else method = strings{idx};
    end
  end  
  idx = strmatch(lower(bbox),strings(4:5));
  if isempty(idx),
    error(message('images:imrotate:unrecognizedBBox', bbox))
  elseif length(idx)>1,
    error(message('images:imrotate:ambiguousBBox', bbox))
  else
    bbox = strings{3+idx};
  end 
else
  error(message('images:imrotate:expectedString'))
end
