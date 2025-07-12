#!/bin/bash

################################################################
## FUNCTIONS ###################################################
################################################################

getSystemID() {
	system=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
}

createDefaultFileConf() {
	echo "Creating the file $file with default configuration..."
	echo "$phrase=false" > "$file"
}

updateFileConf() {
	echo "$phrase=true" > "$file"
}

captureRAM() {
	echo ""
	echo "##############################################"
	echo "## Capturing RAM...                       ####"
	echo "##############################################"

	sudo ./avml/avml $dataDumpFolder/${system}_memorydump.mem

	if [ $? -eq 0 ]; then
		echo "RAM Capture completed successfully"
	else
		echo -e "\e[31mFailed to capture RAM. Something went wrong\e[0m"
		exit 1
	fi
}

updateDependencies() {
	echo ""
	echo "##############################################"
	echo "## Installing dependencies...             ####"
	echo "##############################################"

	dnf update -y

	dnf install -y kernel-devel elfutils python3 zip unzip make gcc git
}

checkAndInstallTools() {
	echo ""
	echo "##############################################"
	echo "## Checking required tools...             ####"
	echo "##############################################"

	if [ ! -d "volatility2" ]; then
		echo "Cloning volatility2 from GitHub..."
		git clone https://github.com/volatilityfoundation/volatility.git volatility2
	else
		echo "volatility2 already exists."
	fi

	if [ ! -d "avml" ]; then
		echo "Cloning AVML from GitHub..."
		git clone https://github.com/microsoft/avml.git avml
		cd avml
		make
		cd ..
	else
		echo "avml already exists."
	fi
}

createProfile() {
	if [ "$value" = "false" ]; then
		updateDependencies
		updateFileConf
		echo "¡Installed dependencies!"

	elif [ "$value" = "true" ]; then
		echo "¡Dependencies up to date!"

	else
		echo "Unknown value in the file $file: $value"
		updateDependencies
		createDefaultFileConf
	fi

	echo ""
	echo "##############################################"
	echo "## Creating profile...                    ####"
	echo "##############################################"

	cd ./volatility2/tools/linux
	make

	if [ $? -eq 0 ]; then
		echo ""
		echo "DWARF module build successfully"

		zip ${system}_profile.zip ./module.dwarf /boot/System.map-$kernel
		mv ${system}_profile.zip ../../../$dataDumpFolder/${system}_profile.zip
		rm module.dwarf
		cd ../../../$dataDumpFolder

		if [ $(uname -m) = "x86_64" ]; then
			echo "[DEFAULT]" > volatilityrc
			echo "PLUGINS=." >> volatilityrc
			echo "PROFILE=Linux${system}_profilex64" >> volatilityrc
			echo "LOCATION=file://${system}_memorydump.mem" >> volatilityrc
		else
			echo "[DEFAULT]" > volatilityrc
			echo "VOLATILITY_PLUGINS=." >> volatilityrc
			echo "VOLATILITY_PROFILE=Linux${system}_profilex32" >> volatilityrc
			echo "VOLATILITY_LOCATION=file://${system}_memorydump.mem" >> volatilityrc
		fi
	else
		echo -e "\e[31mFailed to create the 'dwarf' module. Something went wrong\e[0m"
		exit 1
	fi
}

################################################################
## MAIN SCRIPT #################################################
################################################################

getSystemID
kernel=$(uname -r)
exit=false
captureFolder="capture"
dataDumpFolder="capture/memorydump_$(date +%Y-%m-%d_%H:%M:%S)"
file="dependencies.conf"
phrase="updated_dependencies"

echo "##############################################"
echo "#### Automated Memory Extractor for Linux ####"
echo "####         RPM-based by Galvezsh        ####"
echo "####              Version 1.0             ####"
echo "##############################################"

if [ "$(id -u)" -ne 0 ]; then
	echo "Run AMEL as administrator please"
	exit 1
fi

if [ ! -d "$captureFolder" ]; then
	mkdir "$captureFolder"
fi

if [ ! -d "$dataDumpFolder" ]; then
	mkdir "$dataDumpFolder"
fi

checkAndInstallTools

if [ ! -f "$file" ]; then
	createDefaultFileConf
fi

value=$(grep "$phrase" "$file" | cut -d "=" -f 2)

while [ "$exit" == false ]; do
	read -p "Do you want to capture the RAM? (y/n): " RAMResponse

	if [ "$RAMResponse" == 'y' ]; then
		captureRAM
		exit=true
	elif [ "$RAMResponse" == 'n' ]; then
		exit=true
	else
		echo "Enter a valid value: y/n"
	fi
done

exit=false

while [ "$exit" == false ]; do
	read -p "Do you want to create the profile for volatility? (y/n): " profileResponse

	if [ "$profileResponse" == 'y' ]; then
		createProfile
		exit=true
	elif [ "$profileResponse" == 'n' ]; then
		exit=true
	else
		echo "Enter a valid value: y/n"
	fi
done

echo ""
echo "##############################################"
echo "## Leaving the program...                 ####"
echo "##############################################"
exit 0
