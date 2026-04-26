**FPGA-Based Image Enhancement System**
**🔹 Overview**
This project implements a real-time image enhancement pipeline on FPGA to improve the quality of low-light and low-contrast images.
The system focuses on enhancing edges, brightness, and contrast using efficient hardware-friendly algorithms.
The design leverages FPGA advantages such as parallel processing, pipelining, and low latency to achieve high-speed image processing.

**🔹 Features**
✔ Real-time image enhancement
✔ Noise reduction using Gaussian filtering
✔ Edge detection using Laplacian of Gaussian (LoG)
✔ Image sharpening using Laplacian filtering
✔ Brightness improvement using Gamma Correction
✔ Modular and scalable hardware design
✔ FPGA-friendly implementation (pixel streaming)

**🔹 System Architecture**
Input Image (Camera / Memory)-->Noise Reduction (Gaussian Filter)-->Edge Detection (LoG)-->Sharpening (Laplacian Filter)-->Gamma Correction-->Enhanced Output Image

**🔹 Algorithms Used**
🔸 1. Gaussian Filtering
            Removes noise from the image
            Prepares image for accurate edge detection
🔸 2. Laplacian of Gaussian (LoG)
            Smooths the image and detects edges
            More robust than traditional Sobel operator
🔸 3. Laplacian Sharpening
            Enhances edges and fine details
            Improves overall image clarity
🔸 4. Gamma Correction
            Adjusts brightness non-linearly
            Improves visibility in low-light regions

**🔹 FPGA Implementation Details**
Platform: pynq Z2/ Zybo
Language: Verilog
Design Approach:
    Parallel processing
    Pipelined architecture
    Pixel-by-pixel streaming
    
**🔹 Tools Used**
MATLAB (Algorithm design & testing)
Vivado (Synthesis & Implementation)
 
**🔹 Results**
Improved contrast and visibility in low-light images
Better edge detection compared to traditional methods
Efficient hardware utilization with reduced latency

**🔹 Future Improvements**
CLAHE (Contrast Limited Adaptive Histogram Equalization)
Retinex-based enhancement for advanced low-light scenarios
Hardware optimization for lower power consumption

**🔹 Applications**
Medical imaging (X-ray enhancement)
Surveillance systems
Autonomous vehicles
Robotics and machine vision
Low-light photography
