@echo off
setlocal enabledelayedexpansion

:: Check if Python 3.9 is installed
py -3.9 --version >nul 2>&1
if errorlevel 1 (
    echo Python 3.9 is not installed. Please install it and try again.
    pause
    exit /b 1
)

:: Initialize and update git submodules
git submodule init
git submodule update --remote

:: Set up virtual environment with Python 3.9
py -3.9 -m venv venv
call .\venv\Scripts\activate.bat

:: Upgrade pip and install required packages
python -m pip install --upgrade pip
python -m pip install torch torchvision torchaudio
python -m pip install -r .\modules\tortoise-tts\requirements.txt
python -m pip install -e .\modules\tortoise-tts\
python -m pip install -r .\modules\dlas\requirements.txt
python -m pip install -e .\modules\dlas\
@REM python -m pip install deepspeed-0.8.3+6eca037c-cp39-cp39-win_amd64.whl

:: Download and extract RVC if not already done
set file_name=rvc.zip
set download_rvc=https://huggingface.co/Jmica/rvc/resolve/main/rvc_lightweight.zip?download=true
set extracted_folder=rvc

if exist "%extracted_folder%" (
    echo The folder %extracted_folder% already exists.
    choice /C YN /M "Do you want to delete it and re-extract (Y/N)?"
    if errorlevel 2 goto SkipDeletion
    if errorlevel 1 (
        echo Deleting %extracted_folder%...
        rmdir /S /Q "%extracted_folder%"
    )
)

:SkipDeletion
if not exist "%file_name%" (
    echo Downloading %file_name%...
    curl -L %download_rvc% -o %file_name%
) else (
    echo File %file_name% already exists, skipping download.
)

echo Extracting %file_name%...
tar -xf %file_name%
echo RVC has finished downloading and Extracting.

:: Install RVC requirements
python -m pip install -r .\rvc\requirements.txt

:: Download and install Fairseq if not already done
set download_fairseq=https://huggingface.co/Jmica/rvc/resolve/main/fairseq-0.12.2-cp39-cp39-win_amd64.whl?download=true
set file_name=fairseq-0.12.2-cp39-cp39-win_amd64.whl

if not exist "%file_name%" (
    echo Downloading %file_name%...
    curl -L -O "%download_fairseq%"
    if errorlevel 1 (
        echo Download failed. Please check your internet connection or the URL and try again.
        exit /b 1
    )
) else (
    echo File %file_name% already exists, skipping download.
)

:: Install Fairseq and RVC TTS Pipeline
python -m pip install .\fairseq-0.12.2-cp39-cp39-win_amd64.whl
python -m pip install git+https://github.com/JarodMica/rvc-tts-pipeline.git@lightweight#egg=rvc_tts_pipe

:: Install other requirements (this is done last due to potential package conflicts)
python -m pip install -r .\requirements.txt

:: Setup BnB
.\setup-cuda-bnb.bat

:: Clean up
del *.sh

pause
deactivate
