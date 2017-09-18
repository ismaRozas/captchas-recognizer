function [ output_image ] = nivela_imagen( input_image )
%NIVELA_IMAGEN tries to nivelate the word to delete the introduced
%distortion

[rows cols] = size(input_image);

%find the lowest position in the image, to found the "floor" in the word
image_sum = sum(input_image');
lowest_pos = max (find (image_sum < 95));

built_image = [];

%nivelate the word to that level col by col
for i = 1 : cols
    col = input_image(:,i);
    lowest_col_pos = max (find (col < 1));
    lowest_pos - lowest_col_pos
    regulated_col = circshift(col',lowest_pos - lowest_col_pos);
    built_image = [built_image ; regulated_col];     
end

output_image = built_image';

end

