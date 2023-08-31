import subprocess
from datetime import datetime

files = ['1C', '2C', '3C', '4C', '5C', '6C']


for file in files:
    # read the last line of the file.out
    f = open(f"./inputs/{file}.in", "r")
    lines = f.readlines()
    expected = lines[-1].strip()
    f.close()

    print("Test Case: " + file)

    start = datetime.now()

    out = subprocess.check_output(f"java -jar Mars4_5.jar nc mp1c.asm < ./inputs/{file}.in", shell=True)

    if expected == out.decode('utf-8').strip():
        print("Passed")
    else:
        print("Failed")
        print("Expected: " + expected)
        print("Actual: " + out.decode('utf-8').strip())

    print("Time: " + str(datetime.now() - start))
    print()