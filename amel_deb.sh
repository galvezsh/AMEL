#!/bin/bash

################################################################
## FUNCTIONS ###################################################
################################################################

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

	# Create the memory module
	sudo ./avml $dataDumpFolder/$(lsb_release -i -s)_memorydump.mem

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
	echo "## Install the necessary dependencies     ####"
	echo "##############################################"

	# Actualizar la lista de paquetes
	apt-get update

	# Instalar Dependencias esenciales
	apt-get install -y linux-headers-$kernel dwarfdump python3 zip unzip make gcc git
}

checkAndInstallTools() {
	echo ""
	echo "##############################################"
	echo "## Checking required tools...             ####"
	echo "##############################################"

	# Verificar existencia de volatility2
	if [ ! -d "volatility2" ]; then
		echo "Cloning volatility2 from GitHub..."
		git clone https://github.com/volatilityfoundation/volatility.git volatility2
	else
		echo "volatility2 already exists."
	fi

	# Verificar existencia de avml
	if [ ! -d "avml" ]; then
		echo "Cloning AVML from GitHub..."
		git clone https://github.com/microsoft/avml.git avml
	else
		echo "avml already exists."
	fi
}

createProfile() {
	# Check and assign the value to the variable to update the dependencies
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

	# Create the memory profile
	cd ./volatility-master/tools/linux
	make

	if [ $? -eq 0 ]; then
		echo ""
		echo "DWARF module build successfully"
		
		zip $(lsb_release -i -s)_profile.zip ./module.dwarf /boot/System.map-$kernel
		mv $(lsb_release -i -s)_profile.zip ../../../$dataDumpFolder/$(lsb_release -i -s)_profile.zip
		rm module.dwarf
		cd ../../../$dataDumpFolder

		if [ $(uname -m) = "x86_64" ]; then
			echo "[DEFAULT]" > volatilityrc
			echo "PLUGINS=." >> volatilityrc
			echo "PROFILE=Linux$(lsb_release -i -s)_profilex64" >> volatilityrc
			echo "LOCATION=file://$(lsb_release -i -s)_memorydump.mem" >> volatilityrc

		else
			echo "[DEFAULT]" > volatilityrc
			echo "VOLATILITY_PLUGINS=." >> volatilityrc
			echo "VOLATILITY_PROFILE=Linux$(lsb_release -i -s)_profilex32" >> volatilityrc
			echo "VOLATILITY_LOCATION=file://$(lsb_release -i -s)_memorydump.mem" >> volatilityrc

		fi
	else
		echo -e "\e[31mFailed to create the 'dwarf' module. Something went wrong\e[0m"
		exit 1
	fi
}

################################################################
## MAIN SCRIPT #################################################
################################################################

system=$(lsb_release -i -s)
kernel=$(uname -r)
exit=false
captureFolder="capture"
dataDumpFolder="capture/memorydump_$(date +%Y-%m-%d_%H:%M:%S)"
file="dependencies.conf"
phrase="updated_dependencies"

echo "##############################################"
echo "#### Automated Memory Extractor for Linux ####"
echo "####         DEB-based by Galvezsh        ####"
echo "####              Version 1.0             ####"
echo "##############################################"

# Check if the user is root
if [ "$(id -u)" -ne 0 ]; then
	echo "Run AMEL as administrator please"
	exit 1
fi

# Create memory capture folder
if [ ! -d "$captureFolder" ]; then
	mkdir $captureFolder
fi

# Create data dump folder
if [ ! -d "$dataDumpFolder" ]; then
	mkdir $dataDumpFolder
fi

# Verificar herramientas necesarias
checkAndInstallTools

# Check if the conf file exists
if [ ! -f "$file" ]; then
	createDefaultFileConf
fi

# Read the value from the conf file
value=$(grep "$phrase" "$file" | cut -d "=" -f 2)

# Ask user about RAM capture
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

# Ask user about creating the profile
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
