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

checkAndInstallTools() {
	echo ""
	echo "##############################################"
	echo "## Installing dependencies (Arch)         ####"
	echo "##############################################"

	# Actualizar la base de datos e instalar paquetes
	pacman -Sy --noconfirm base-devel linux-headers dwarfdump zip unzip python git
}

checkAndCloneTools() {
	echo ""
	echo "##############################################"
	echo "## Checking required tools...             ####"
	echo "##############################################"

	# Verificar Volatility 2
	if [ ! -d "./volatility" ]; then
		echo "Cloning Volatility 2..."
		git clone https://github.com/volatilityfoundation/volatility.git
	else
		echo "Volatility 2 already present."
	fi

	# Verificar AVML
	if [ ! -d "./avml" ]; then
		echo "Cloning AVML..."
		git clone https://github.com/microsoft/avml.git
	else
		echo "AVML already present."
	fi
}

captureRAM() {
	echo ""
	echo "##############################################"
	echo "## Capturing RAM...                       ####"
	echo "##############################################"

	# Compilar AVML si no existe binario
	if [ ! -f ./avml/avml ]; then
		echo "Compiling AVML..."
		cd avml
		make
		cd ..
	fi

	# Ejecutar AVML
	sudo ./avml/avml "$dataDumpFolder/${system}_memorydump.mem"

	if [ $? -eq 0 ]; then
		echo "RAM Capture completed successfully"
	else
		echo -e "\e[31mFailed to capture RAM. Something went wrong\e[0m"
		exit 1
	fi
}

createProfile() {
	if [ "$value" = "false" ]; then
		checkAndInstallTools
		updateFileConf
		echo "Dependencies installed!"

	elif [ "$value" = "true" ]; then
		echo "Dependencies already installed!"

	else
		echo "Unknown value in $file: $value"
		checkAndInstallTools
		createDefaultFileConf
	fi

	echo ""
	echo "##############################################"
	echo "## Creating Volatility profile...         ####"
	echo "##############################################"

	cd ./volatility/tools/linux
	make

	if [ $? -eq 0 ]; then
		echo "DWARF module built successfully"

		zip "${system}_profile.zip" module.dwarf "/boot/System.map-${kernel}"
		mv "${system}_profile.zip" "../../../$dataDumpFolder/${system}_profile.zip"
		rm module.dwarf
		cd ../../../$dataDumpFolder

		# Crear archivo volatilityrc
		echo "[DEFAULT]" > volatilityrc
		echo "PLUGINS=." >> volatilityrc

		if [ "$(uname -m)" = "x86_64" ]; then
			echo "PROFILE=Linux${system}_profilex64" >> volatilityrc
		else
			echo "PROFILE=Linux${system}_profilex32" >> volatilityrc
		fi

		echo "LOCATION=file://${system}_memorydump.mem" >> volatilityrc

	else
		echo -e "\e[31mFailed to create DWARF module. Something went wrong\e[0m"
		exit 1
	fi
}

################################################################
## MAIN SCRIPT #################################################
################################################################

system=$(lsb_release -i -s 2>/dev/null || echo "arch")
kernel=$(uname -r)
exit=false
captureFolder="capture"
dataDumpFolder="capture/memorydump_$(date +%Y-%m-%d_%H:%M:%S)"
file="dependencies.conf"
phrase="updated_dependencies"

echo "##############################################"
echo "#### Automated Memory Extractor for Linux ####"
echo "####         ARCH-based by Galvezsh       ####"
echo "####              Version 1.0             ####"
echo "##############################################"

if [ "$(id -u)" -ne 0 ]; then
	echo "Run AMEL as root (sudo)."
	exit 1
fi

[ ! -d "$captureFolder" ] && mkdir "$captureFolder"
[ ! -d "$dataDumpFolder" ] && mkdir "$dataDumpFolder"

checkAndCloneTools

[ ! -f "$file" ] && createDefaultFileConf

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
