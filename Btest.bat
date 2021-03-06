@echo off

SET CONFIGURATION=Debug
SET PROJECT_NAME=model
SET PROJECT_ULD="SULDWavTemplate/output/standalone/model3.uld"

: Underflow and overflow from model 1 to model 2 happening on HARD_CLIPPING & 6 channels output
: Channel options 0 -> 2 channels, 1 -> 4 channels, 2 -> 6 channels
SET /A CHANNEL_NUM=0
: Distortion option options 0 -> hard clipping, 2 -> full wave recifier, 3 -> half wave recifier
SET /A DISTORTION_OPTION=0
: Enable
SET /A ENABLE=0

SET SIMULATOR=C:\CirrusDSP\bin\cmdline_simulator.exe -silent
SET COMPARE="..//tools//PCMCompare.exe"


: Delete log files first.

del /Q OutCmp\*
del /Q OutStreams\*


: For each Test stream
for %%f in (..\TestStreams\*.*) do ( 
	@echo Running tests for stream: %%~nf%%~xf

	: Execute Model 0, Model 1 and Model 2
	echo     model 0
    "%CONFIGURATION%\model0.exe" "%%f" "OutStreams//%%~nf_model0.wav" "%CHANNEL_NUM%" "%DISTORTION_OPTION%" "%ENABLE%"
	echo     model 1
	"%CONFIGURATION%\model1.exe" "%%f" "OutStreams//%%~nf_model1.wav" "%CHANNEL_NUM%" "%DISTORTION_OPTION%" "%ENABLE%"
	echo     model 2
	"%CONFIGURATION%\model2.exe" "%%f" "OutStreams//%%~nf_model2.wav" "%CHANNEL_NUM%" "%DISTORTION_OPTION%" "%ENABLE%"

	: Execute Model 3
	echo     model 3
	(
		@echo ^<?xml version="1.0" encoding="UTF-8" standalone="yes"?^>
		@echo ^<CL_PROJECT^>
		@echo     ^<argv^>%%f OutStreams\%%~nf_model3.wav %CHANNEL_NUM% %DISTORTION_OPTION% %ENABLE%^</argv^>
		@echo     ^<FILE_IO_CFG block_type="Input" channels_per_line="2" delay="0" file_mode="PCM" index="0" justification="Left" sample_format="LittleEndian" sample_rate="48000" sample_size="32"/^>
		@echo     ^<FILE_IO_CFG block_type="Output" channels_per_line="2" delay="0" file_mode="PCM" index="0" justification="Left" sample_format="LittleEndian" sample_rate="48000" sample_size="32"/^>
		@echo     ^<MEMORY_CFG^>
		@echo         ^<ULD_FILE disk_path=%PROJECT_ULD%/^>
		@echo     ^</MEMORY_CFG^>
		@echo     ^<PROFILE_CFG enable="on"/^>
		@echo     ^<SCP_CFG load_delay="0"/^>
		@echo ^</CL_PROJECT^>
	
	) > SimulatorConfigurationTemp.sbr
	

	%SIMULATOR% -project SimulatorConfigurationTemp.sbr -max_cycles 1000000

	: Generate new logs
	%COMPARE% OutStreams//%%~nf_model0.wav OutStreams//%%~nf_model1.wav 2> OutCmp//%%~nf_Model0_vs_Model1.txt
	%COMPARE% OutStreams//%%~nf_model1.wav OutStreams//%%~nf_model2.wav 2> OutCmp//%%~nf_Model1_vs_Model2.txt
	%COMPARE% OutStreams//%%~nf_model2.wav OutStreams//%%~nf_model3.wav 2> OutCmp//%%~nf_Model2_vs_Model3.txt

	
)