import subprocess
import sys
import os

def main():
    # Ensure the binary exists
    binary = "./build/nemu"
    if not os.path.exists(binary):
        print(f"Error: {binary} not found. Please run 'make' first.")
        return

    # Start the C emulator as a subprocess
    # Using bufsize=0 to disable Python-side buffering
    process = subprocess.Popen(
        [binary],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        bufsize=0
    )

    print(f"--- Python Monitor Started (PID: {process.pid}) ---")

    try:
        # Start the execution in the emulator by sending 'c'
        process.stdin.write(b"c\n")
        process.stdin.flush()

        # Read byte-by-byte from the emulator's stdout
        while True:
            char_byte = process.stdout.read(1)
            if not char_byte:
                break
            
            # Decode and write to Host terminal
            char = char_byte.decode('utf-8', errors='ignore')
            sys.stdout.write(char)
            sys.stdout.flush()

    except KeyboardInterrupt:
        print("\nMonitor interrupted by user.")
    finally:
        process.terminate()
        process.wait()
        print("\n--- Emulator Terminated ---")

if __name__ == "__main__":
    main()
