import pexpect
import time
import sys

# Calculate sleep time: 2 hours and 53 minutes in seconds
# (2 * 3600) + (53 * 60) = 7200 + 3180 = 10380 seconds
wait_time = 10380 

print(f"Sleeping for 2 hours and 53 minutes ({wait_time} seconds)...")
time.sleep(wait_time)
print("Awake! Launching Claude Code...")

# The command you want to execute
command = 'claude "Fix all issues that needs to be completed of sheet https://docs.google.com/spreadsheets/d/1SzUYrrdi2PQYCJbgW73PWlYPSw_ZhaDWQ_o0H5XApy0/edit?usp=sharing"'

# Spawn the interactive process
# Note: pexpect works natively on macOS/Linux/WSL. 
child = pexpect.spawn(command, encoding='utf-8', timeout=None)

# Route the output to your console so you can see what it did when you wake up
child.logfile = sys.stdout

while True:
    try:
        # Look for indicators of an interactive prompt (like a '?' or a specific phrase)
        # Adjust the strings inside the list if Claude's prompt differs slightly
        index = child.expect([r'\[\?\]', r'(?i)Do you want to', pexpect.EOF])

        if index in [0, 1]:
            # Prompt detected. Wait 0.5 seconds for the menu UI to fully render
            time.sleep(0.5)

            # Send the Down Arrow escape sequence (\x1b[B) to move to the second option
            # ("Yes, don't ask again")
            child.send('\x1b[B')
            time.sleep(0.2)

            # Send the Enter key to confirm the selection
            child.send('\r')

        elif index == 2:
            print("\nExecution completed cleanly.")
            break

    except pexpect.EOF:
        print("\nProcess ended.")
        break
    except Exception as e:
        print(f"\nAn error occurred: {e}")
        break