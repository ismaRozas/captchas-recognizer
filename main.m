% ************************ captcha recognizer ***************************
% ***********************************************************************

clc;
clear all;
close all;
warning off;

%read the image, normalize and binarize it
image = imread('imagenes/image2.jpeg');
[rows cols] = size(image);
image = double(image) ./255;







%------------------------- cleaning algorithm ----------------------------
%clean the image from blurred zones, salt&pepper noise, irregular
%borders...

%adaptive umbralization of the image --> taking 9x9 fragments, calculate
%the mean and umbralize based on it
for i=2:rows-1
    for j=2:cols-1
        %take the 9x9 fragment
        square = [image((i-1:i+1),(j-1:j+1))];
        %calculate the mean luminance value
        square_mean = sum(sum(square))/9;
        %umbralize the image
        image = (image > (square_mean/2));
    end
end

%image = image * 255;
%imshow([image]);

%sharpening the image to avoid blurred letters
H = padarray(2,[2 2]) - fspecial('gaussian' ,[5 5],2);
%applying the filter 2 times to the image
image = imfilter(image,H);
image = imfilter(image,H);

%eliminate isolated points
image = remove_isolated_points(image);

imshow(image)
%------------------------------------------------------------------------












%------------------------- divisor algorithm ----------------------------
%this algorithm tries to divide the captcha in two zones: one per word. For
%that, we will try to find white zones from the top to the bottom of the
%image.

%finding the columns with black pixels (letters)
min_values_array = min(image);

%finding the columns with letters to concatenate it
letters = find(min_values_array > 0);

%find discontinuities in letters array to find letters
found_letters=[];
for idx=2: length(letters)
    
    %discontinuity...
    if (letters(idx) > letters(idx-1) +1)
        %... enough large to be considered as a space between words
        if(letters(idx) > letters(idx-10)+10)
            %word´s end
            found_letters(1,idx) = letters(idx);
            
            %word´s start
            found_letters(2,idx) = letters(idx-1);
        end
    end    
end

%delete null possitions in found_letters
found_letters = found_letters(: , find(found_letters(1,:)>0)');

%ploting the words found
[word_rows word_cols] = size(found_letters);

for plot_idx = 1 : 1 %word_cols
    figure
    imshow( image(:, found_letters(2,plot_idx):found_letters(1,plot_idx) ) *255 );
end
%------------------------------------------------------------------------


%%





%---------------------- straightened algorithm --------------------------
%try to straighten the twisted word. 3 steps:
%   - rotate the word
%   - raise up the letters
%   - put all the letters in the same elevation

%take the image to straight
word = ~image(:, found_letters(2,1):found_letters(1,1) );

%initialize the minimum distance between letters in a word to the max value
min_distance = rows

%best straightened image, stored to use it
better_word = [];

% +++++++ rotate +++++++
%find the best rotation to equilibrate the word
for angle = -90:2:90
    
    %rotate the image
    rotated_word = ~imrotate(word,angle);
    
    %calculate the angle of the word
    distance = equilibrated_word(rotated_word);
    
    %take the better equilibrated word
    if (distance < min_distance)
        min_distance = distance;
        better_word = rotated_word;
    end
end

better_word2 = remove_isolated_points(better_word);
% ++++++++++++++++++++++




% ++++++ nivelate ++++++
better_word3 = nivela_imagen(better_word2);
imshow(better_word3);
% ++++++++++++++++++++++


%[test_rows test_cols] = size(test)
%white_rows = sum(test');
%deleting white rows in the upper part of the image
%white_row_position = find(white_rows == test_cols)


%------------------------------------------------------------------------































