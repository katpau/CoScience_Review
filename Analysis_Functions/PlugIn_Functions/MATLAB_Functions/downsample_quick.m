function New = downsample_quick(Data, DP)
DP_original = size(Data,2);
New=nan(size(Data,1), DP, size(Data,3));
for iel = 1:size(Data,1)
   for it = 1:size(Data,3)
       New(iel, :, it) = interp1(1:DP_original, Data(iel,:,it), linspace(1, DP_original, DP), 'linear');
    end     
end
end
