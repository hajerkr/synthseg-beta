echo $#!/usr/bin/env bash 

GEAR=fw-SynthSeg-gear-refactored
IMAGE=beta-synthseg:0.1.1
LOG=synthseg-0.0.1-675087b0de349c9bd8c2d6dc


# Command:
docker run -it --rm --entrypoint bash\
	-v $1/unity/fw-gears/${GEAR}/app/:/flywheel/v0/app\
	-v $1/unity/fw-gears/${GEAR}/utils:/flywheel/v0/utils\
	-v $1/unity/fw-gears/${GEAR}/run.py:/flywheel/v0/run.py\
	-v $1/unity/fw-gears/${GEAR}/${LOG}/input:/flywheel/v0/input\
	-v $1/unity/fw-gears/${GEAR}/${LOG}/output:/flywheel/v0/output\
	-v $1/unity/fw-gears/${GEAR}/${LOG}/work:/flywheel/v0/work\
	-v $1/unity/fw-gears/${GEAR}/${LOG}/config.json:/flywheel/v0/config.json\
	-v $1/unity/fw-gears/${GEAR}/${LOG}/manifest.json:/flywheel/v0/manifest.json\
	-v $1/unity/fw-gears/${GEAR}/fslinstaller.py:/flywheel/v0/fslinstaller.py\
	$IMAGE
