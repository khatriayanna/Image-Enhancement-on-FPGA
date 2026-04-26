% ============================================================
% Image Enhancement - (Variance-based Gamma)
% ============================================================

clc;
clear;
close all;

%% ============================================================
% STEP 1: Read Input Image
%% ============================================================

[file,path] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff'}, 'Select an image');

if isequal(file,0)
    disp('No file selected');
    return;
end

Irgb = imread(fullfile(path,file));
Irgb = double(Irgb);

%% ============================================================
% STEP 2: Grayscale + Normalization
%% ============================================================

R = Irgb(:,:,1);
G = Irgb(:,:,2);
B = Irgb(:,:,3);

I = 0.2989*R + 0.5870*G + 0.1140*B;

I = I / max(I(:));     % Normalize
I0 = I;

[H,W] = size(I);

%% ============================================================
% STEP 3: Gaussian Smoothing (5x5)
%% ============================================================

G = [1  4  6  4  1;
     4 16 24 16  4;
     6 24 36 24  6;
     4 16 24 16  4;
     1  4  6  4  1] / 256;

Pg = zeros(H+4,W+4);
Pg(3:end-2,3:end-2) = I;

% Border replication
Pg(1,:) = Pg(3,:); Pg(2,:) = Pg(3,:);
Pg(end,:) = Pg(end-2,:); Pg(end-1,:) = Pg(end-2,:);
Pg(:,1) = Pg(:,3); Pg(:,2) = Pg(:,3);
Pg(:,end) = Pg(:,end-2); Pg(:,end-1) = Pg(:,end-2);

Ig = zeros(H,W);

for i = 1:H
    for j = 1:W
        Ig(i,j) = sum(sum(Pg(i:i+4,j:j+4).*G));
    end
end

%% ============================================================
% STEP 4: Laplacian of Gaussian + Zero Crossing
%% ============================================================

Lk = [0  1  0;
      1 -4  1;
      0  1  0];

Pl = zeros(H+2,W+2);
Pl(2:end-1,2:end-1) = Ig;

Pl(1,:) = Pl(2,:); Pl(end,:) = Pl(end-1,:);
Pl(:,1) = Pl(:,2); Pl(:,end) = Pl(:,end-1);

LoG = zeros(H,W);

for i = 1:H
    for j = 1:W
        LoG(i,j) = sum(sum(Pl(i:i+2,j:j+2).*Lk));
    end
end

% -------- Zero Crossing Detection --------
ZC = zeros(H,W);

for i = 2:H-1
    for j = 2:W-1

        patch = LoG(i-1:i+1 , j-1:j+1);

        if max(patch(:))*min(patch(:)) < 0
            ZC(i,j) = 1;
        end
    end
end

LoG = LoG .* ZC;

LoG_vis = abs(LoG);
LoG_vis = LoG_vis / max(LoG_vis(:));

%% ============================================================
% STEP 5: Guided Filtering (Replaces Wiener)
%% ============================================================

r = 2;              % window radius
eps = 0.01;         % regularization parameter

pad = r;
Pg = padarray(Ig,[pad pad],'replicate');

Iw = zeros(H,W);

for i = 1:H
    for j = 1:W
        
        window = Pg(i:i+2*r, j:j+2*r);
        
        mean_I = mean(window(:));
        var_I  = mean(window(:).^2) - mean_I^2;
        
        a = var_I / (var_I + eps);
        b = mean_I * (1 - a);
        
        Iw(i,j) = a * Ig(i,j) + b;
    end
end

%% ============================================================
% STEP 6: Laplacian Sharpening (Reduced Gain)
%% ============================================================

alpha = 2.0;     % Reduced

I_lap = Iw - alpha*LoG;
I_lap = min(max(I_lap,0),1);

%% ============================================================
% STEP 7: Unsharp Masking (Moderate Gain)
%% ============================================================

Mask = I_lap - Ig;

mask_gain = 2.0;

I_mask = I_lap + mask_gain*Mask;
I_mask = min(max(I_mask,0),1);

%% ============================================================
% STEP 8: Variance-Based Adaptive Gamma Correction (ENHANCED)
%% ============================================================

mean_intensity = mean(I_mask(:));
var_intensity  = var(I_mask(:));

% Normalize variance (important for stability)
var_norm = var_intensity / (var_intensity + 1);

% Tunable weights (you can tweak later)
w_mean = 0.6;
w_var  = 0.4;

% Compute gamma
gamma = w_mean*(1 - mean_intensity) + w_var*(1 - var_norm);

% Clamp gamma (VERY IMPORTANT for stability)
gamma = max(0.3, min(1.5, gamma));

fprintf('\nGamma used: %.3f\n', gamma);
fprintf('Mean: %.4f | Variance: %.4f\n', mean_intensity, var_intensity);

% Apply gamma correction
I_final = I_mask.^gamma;

%% ============================================================
% STEP 9: Quality Metrics (Entropy, SSIM, AMBE)
%% ============================================================

% -------- Entropy --------
entropy_input  = entropy(I0);
entropy_output = entropy(I_final);

fprintf('\nEntropy Improvement: %.4f\n', entropy_output - entropy_input);

% -------- SSIM --------
ssim_val = ssim(I_final, I0);

% -------- AMBE --------
ambe = abs(mean(I0(:)) - mean(I_final(:)));

% -------- Display Results --------
fprintf('\n====== QUALITY METRICS ======\n');
fprintf('Entropy (Input)  : %.4f\n', entropy_input);
fprintf('Entropy (Output) : %.4f\n', entropy_output);
fprintf('SSIM             : %.4f\n', ssim_val);
fprintf('AMBE             : %.6f\n', ambe);

%% ============================================================
% STEP 10: Visualization
%% ============================================================

figure('Units','normalized','Position',[0 0 1 1]);

subplot(2,4,1), imshow(I0,[]), title('Input');
subplot(2,4,2), imshow(Ig,[]), title('Gaussian');
subplot(2,4,3), imshow(LoG_vis,[]), title('LoG + ZC');
subplot(2,4,4), imshow(Iw,[]), title('Guided Filter');

subplot(2,4,5), imshow(I_lap,[]), title('Laplacian Sharp');
subplot(2,4,6), imshow(abs(Mask),[]), title('Mask');
subplot(2,4,7), imshow(I_mask,[]), title('After Mask');
subplot(2,4,8), imshow(I_final,[]), title('Final (Variance-based Gamma)');

%% ============================================================
% Side-by-Side Comparison
%% ============================================================

figure;

subplot(1,2,1), imshow(I0,[]), title('Original');
subplot(1,2,2), imshow(I_final,[]), title('Enhanced');

figure;

subplot(1,3,1), imshow(I0,[]), title('Original');
subplot(1,3,2), imshow(I_mask,[]), title('Before Gamma');
subplot(1,3,3), imshow(I_final,[]), title('After Variance Gamma');

%% ============================================================
% PSNR CALCULATION FOR EACH STAGE
%% ============================================================
% NOTE: PSNR may decrease since enhancement alters original image.
% Use Entropy, SSIM, and AMBE for better evaluation.

psnr_gaussian = psnr(Ig, I0);
psnr_log      = psnr(LoG_vis, I0);
psnr_wiener   = psnr(Iw, I0);
psnr_lap      = psnr(I_lap, I0);
psnr_mask     = psnr(I_mask, I0);
psnr_final    = psnr(I_final, I0);

fprintf('\n===== PSNR RESULTS (dB) (MOD 3) =====\n');
fprintf('Gaussian  : %.2f dB\n', psnr_gaussian);
fprintf('LoG + ZC  : %.2f dB\n', psnr_log);
fprintf('Guided    : %.2f dB\n', psnr_wiener);
fprintf('Sharpen   : %.2f dB\n', psnr_lap);
fprintf('Mask      : %.2f dB\n', psnr_mask);
fprintf('Final     : %.2f dB\n', psnr_final);
