"""
uart_test.py
Sends an image (or a generated test pattern) to the PYNQ-Z2 over UART,
receives the processed pixels back, and saves them to a text file in
the same format your tb.v testbench used (one pixel value per line).

FINAL STATUS (this is the production version, diagnostics removed):
  - SEND_WARMUP = 1551: the true pixel_in->valid_out latency traced
    through image_pipeline.v (matches tb.v v5's WARMUP exactly). This
    is how many dummy zero bytes get sent before/after the real image
    to prime and flush the pipeline. Confirmed correct.
  - CAPTURE_OFFSET = 1555: the true offset into the OUTPUT byte stream
    where the real 256-pixel image actually starts. This is 4 bytes
    later than SEND_WARMUP would suggest -- that extra +4 lives in the
    UART/FIFO transport path (uart_rx/elastic FIFO/uart_tx), which
    tb.v never exercises since it drives image_pipeline directly.
    Measured empirically: captured the full 3358-byte round trip
    unsplit, then slid a 256-sample window across it and found the
    lowest mean-abs-error match against sim_output_16x16.txt at byte
    index 1555 (error 5.30, consistent with normal fixed-point
    rounding noise -- not a further misalignment).
  - Also carries forward from earlier fixes: pinned OS buffer size,
    input/output buffer purge on open, and threaded send/receive (all
    needed to get a reliable, complete capture in the first place --
    see prior versions' changelog if any of these need revisiting).
"""

import serial
import time
import threading
import hashlib
import numpy as np

# ============================================================
# CONFIG — edit these before running
# ============================================================
COM_PORT        = "COM6"      # <-- change to your USB-TTL adapter's port
BAUD_RATE       = 115200      # must match uart_rx/uart_tx BAUD_RATE parameter
IMG_WIDTH       = 16          # 16 for the small test, 256 for the real image
IMG_HEIGHT      = 16
SEND_WARMUP     = 1551        # true pipeline priming latency -- do not change
CAPTURE_OFFSET  = 1555        # measured true start of real data in the output stream
OUTPUT_FILE     = "hw_output.txt"
TIMEOUT_SEC     = 120          # total budget for the full round-trip capture

# ============================================================
# STEP 1: Build or load the test image
# ============================================================
def make_test_pattern(width, height):
    """Simple gradient test pattern for the 16x16 sanity check."""
    img = np.zeros((height, width), dtype=np.uint8)
    for y in range(height):
        for x in range(width):
            img[y, x] = (x * 16 + y * 16) % 256
    return img

def load_image_from_txt(path, width, height):
    """Load a pixel list (one value per line) - same format as your
    MATLAB scripts already use for xray.txt."""
    pixels = np.loadtxt(path, dtype=np.uint8)
    return pixels.reshape((height, width))

# ============================================================
# STEP 2: Open serial port
# ============================================================
def open_serial():
    ser = serial.Serial(COM_PORT, BAUD_RATE, timeout=1)
    # Pin the OS-level receive buffer in code -- Device Manager's
    # "Advanced" buffer setting doesn't always survive a replug or
    # driver reload, and a silently-small default causes mid-stream
    # byte loss on transfers of a few thousand bytes.
    if hasattr(ser, "set_buffer_size"):
        ser.set_buffer_size(rx_size=8192, tx_size=8192)
    time.sleep(2)  # allow adapter/board to settle after opening the port
    # Purge anything already queued from a prior run so this run's
    # first read is guaranteed to be fresh data, not stale leftovers.
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    print(f"Bytes waiting immediately after purge: {ser.in_waiting}")  # should be 0
    return ser

# ============================================================
# STEP 3: Send image bytes (with warm-up/tail padding)
# ============================================================
def send_image(ser, img):
    flat = img.flatten().astype(np.uint8)

    warmup_bytes = bytes([0] * SEND_WARMUP)
    tail_bytes   = bytes([0] * SEND_WARMUP)

    print(f"Sending {SEND_WARMUP} warm-up bytes...")
    ser.write(warmup_bytes)

    print(f"Sending {len(flat)} real image pixels...")
    ser.write(flat.tobytes())

    print(f"Sending {SEND_WARMUP} tail-flush bytes...")
    ser.write(tail_bytes)

# ============================================================
# STEP 4: Receive the full round-trip stream unsplit, then slice
# out the real image at the measured CAPTURE_OFFSET. Capturing the
# whole thing in one continuous read (rather than splitting into
# separate discard/receive/drain phases) is what proved reliable --
# keep doing it that way rather than reintroducing the split.
# ============================================================
def capture_and_extract(ser, img, num_pixels):
    total_expected = 2 * SEND_WARMUP + num_pixels
    result = {}

    def receiver():
        buf = bytearray()
        start_time = time.time()
        print(f"Capturing full stream ({total_expected} bytes expected)...")
        while len(buf) < total_expected:
            chunk = ser.read(total_expected - len(buf))
            if chunk:
                buf.extend(chunk)
            if time.time() - start_time > TIMEOUT_SEC:
                print(f"WARNING: Timeout. Only received {len(buf)} / {total_expected} bytes.")
                break
        result['data'] = buf

    t = threading.Thread(target=receiver)
    t.start()
    send_image(ser, img)
    t.join()

    full = result['data']
    if len(full) < CAPTURE_OFFSET + num_pixels:
        print(f"WARNING: capture too short ({len(full)} bytes) to slice "
              f"{num_pixels} pixels starting at offset {CAPTURE_OFFSET} -- "
              f"rerun the transfer, this result is not usable.")
        return full[CAPTURE_OFFSET:], False

    real_pixels = full[CAPTURE_OFFSET: CAPTURE_OFFSET + num_pixels]
    return real_pixels, True

# ============================================================
# STEP 5: Save output in the same format your MATLAB script expects
# ============================================================
def save_output(received_bytes, path):
    with open(path, "w") as f:
        for b in received_bytes:
            f.write(f"{b}\n")
    print(f"Saved {len(received_bytes)} pixels to {path}")
    print(f"MD5 of capture: {hashlib.md5(bytes(received_bytes)).hexdigest()}")

# ============================================================
# MAIN
# ============================================================
if __name__ == "__main__":
    num_pixels = IMG_WIDTH * IMG_HEIGHT

    # Choose ONE of these:
    img = make_test_pattern(IMG_WIDTH, IMG_HEIGHT)     # for 16x16 sanity test
    # img = load_image_from_txt("xray.txt", IMG_WIDTH, IMG_HEIGHT)  # for real image

    ser = open_serial()

    real_pixels, ok = capture_and_extract(ser, img, num_pixels)
    save_output(real_pixels, OUTPUT_FILE)
    if not ok:
        print("Capture was incomplete -- do not trust this hw_output.txt, rerun.")

    ser.close()
    print("Done.")
