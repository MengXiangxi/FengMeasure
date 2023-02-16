% Calculate bladder
files = dir("./samples/Bladder/*.tif");
fnames = strings(length(files),1);
bladder_mean = zeros(length(files),1);
for ii = 1:length(files)
    val = fengBaldder(fullfile(files(ii).folder,files(ii).name), 75, 8E5, 2800);
    fnames(ii) = files(ii).name;
    bladder_mean(ii) = val;
end
T_bladder = table(fnames, bladder_mean);
writetable(T_bladder, './bladder.csv')

% Calculate kidney
files = dir("./samples/Kidney/*.tif");
fnames = strings(length(files),1);
kidney_mean = zeros(length(files),2);
for ii = 1:length(files)
    [val1, val2] = fengKidney(fullfile(files(ii).folder,files(ii).name), 35, 4E5, 512);
    fnames(ii) = files(ii).name;
    kidney_mean(ii, 1) = val1;
    kidney_mean(ii, 2) = val2;
end
T_kidney = table(fnames, kidney_mean);
writetable(T_kidney, './kidney.csv')


%% Functions

function quantity = fengBaldder(imgName, N, threshold_tail, M)
% Use default parameters
if nargin < 2
    N = 35; % N must be an odd number
    threshold_tail = 3E5;
    M = 512;
end

% Read image
img = imread(imgName);
% Processing dimension
side = (N-1)/2;

% Remove tail
tail = detTail(img, threshold_tail, N);
img = img.*uint16(ones(size(img)) - tail);

% Find first hot zone and remove it
[max_r, max_c] = areaMax(img, N);
quantity = meanOfMaxM(img(max_r-side:max_r+side, max_c-side:max_c+side), M)
img(max_r-side:max_r+side, max_c-side:max_c+side) = 0;

% Output the image
fig = imagesc(img);

% Save the image
outName = extractBefore(imgName, ".tif");
saveas(fig, outName, 'png')

end

function [quantity1, quantity2] = fengKidney(imgName, N, threshold_tail, M)

% Use default parameters
if nargin < 2
    N = 35;
    threshold_tail = 3E5;
    M = 512;
end

% Read image
img = imread(imgName);
% Processing dimension
side = (N-1)/2;

% Remove tail
tail = detTail(img, threshold_tail, N);
img = img.*uint16(ones(size(img)) - tail);

% Find first hot zone and remove it
[max_r, max_c] = areaMax(img, N);
quantityA = meanOfMaxM(img(max_r-side:max_r+side, max_c-side:max_c+side), M)
img(max_r-side:max_r+side, max_c-N:max_c+N) = 0;
cache = max_r;

% Find the second hot zone and remove it
[max_r, max_c] = areaMax(img, N);
quantityB = meanOfMaxM(img(max_r-side:max_r+side, max_c-side:max_c+side), M)
img(max_r-side:max_r+side, max_c-N:max_c+N) = 0;

if max_r > cache
    quantity1 = quantityA;
    quantity2 = quantityB;
else
    quantity1 = quantityB;
    quantity2 = quantityA;
end

% Output the image
fig = imagesc(img);

% Save the image
outName = extractBefore(imgName, ".tif");
saveas(fig, outName, 'png')

end

function tail = detTail(img, threshold_tail, N)
FilterM = 1/N*ones(N);
gradgrad_img = imgradient(imgradient(img));
gradgrad_filtered = filter2(FilterM, gradgrad_img);
tail = gradgrad_filtered;
tail(tail<=threshold_tail) = 0;
tail(tail>threshold_tail) = 1;
end

function [max_r, max_c] = areaMax(img, N)
FilterM = 1/N*ones(N);
img_filtered = filter2(FilterM, img);
[~, max_ind] = max(img_filtered(:));
[max_r, max_c] = ind2sub(size(img), max_ind);
end

function mean_val = meanOfMaxM(matrix, m)
values = sort(matrix(:),"descend");
mean_val = mean(values(1:m));
end
