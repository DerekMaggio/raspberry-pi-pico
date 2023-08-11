import argparse
import json
import os
import subprocess

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def run_subprocess_command(package: str, package_url: str)-> None:
    # Replace the command below with your desired subprocess command
    cmd = (
        f"echo 'Removing: {PROJECT_ROOT}/firmware/{package}.mpy' && "
        f"rm -f {PROJECT_ROOT}/firmware/{package}.mpy && "
        f"echo 'Downloading package: {package}' && "
        f"curl -o {package}.py {package_url} && "
        f"echo 'Cross Compiling package: {package}' && "
        f"{PROJECT_ROOT}/tools/mpy-cross {package}.py && "
        f"echo 'Moving mpy files to firmware directory' && "
        f"mv *.mpy {PROJECT_ROOT}/firmware/"
    )
    subprocess.run(cmd, shell=True)

def iterate_packages(json_file: str) -> None:
    with open(json_file) as f:
        data = json.load(f)
        packages = data.get('PACKAGES', [])

        for package_name, package_url in packages.items():
            run_subprocess_command(package_name, package_url)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("json_file", help="Path to the json file")
    args = parser.parse_args()
    iterate_packages(args.json_file)
    
