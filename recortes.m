
%%

% %------------------------- snake algorithm ------------------------------
% %trying to separate the different letters by snake algorithm
% last_empty_col = 0;
% 
% for i=1: 20
%     %in each column, we will try to reach the lower part of the image
%     %without find any letter. This is, we will follow the "0" vertically
%     %until the last row. By this way we can determine where are the letters
% 
%     for j=1:rows
%         if(image(i,j) == 0)
%             break;
%         end
%     end
%     
%     %if we don´t find any letter in that column, advance the pointer to the
%     %next column
%     if (j==rows)
%         start_letter = i;
%     end
%     
%     
% end
% %------------------------------------------------------------------------