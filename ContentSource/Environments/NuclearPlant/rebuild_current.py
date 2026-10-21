from pathlib import Path
import subprocess,sys
R=Path(__file__).resolve().parent
subprocess.run([sys.executable,str(R/'Batch06_Expansion/rebuild.py'),*sys.argv[1:]],check=True)
