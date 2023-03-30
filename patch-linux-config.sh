#!/usr/bin/bash

if [[ ! -x ./scripts/config ]]; then
  echo "This script must be executed in Linux source tree!"
  exit 1
fi

configs=(
    '-e' 'SOC_STARFIVE' # StarFive board support
    '-e' 'SOC_SIFIVE' '-e' 'GPIO_SIFIVE' '-e' 'SIFIVE_CCACHE' '-e' 'EDAC_SIFIVE' '-e' 'PCIE_FU740' '-m' 'PWM_SIFIVE' # SiFive board support
    '-e' 'ERRATA_THEAD' '-e' 'ERRATA_THEAD_PBMT' # # THead board support
    '-e' 'SOC_MICROCHIP_POLARFIRE' '-e' 'PCIE_MICROCHIP_HOST' '-e' 'PCIE_XILINX' '-e' 'SERIAL_OF_PLATFORM' '-m' 'USB_MUSB_POLARFIRE_SOC' '-m' 'RTC_DRV_POLARFIRE_SOC' '-m' 'POLARFIRE_SOC_MAILBOX' '-m' 'I2C_MICROCHIP_CORE' '-m' 'POLARFIRE_SOC_SYS_CTRL' '-m' 'HW_RANDOM_POLARFIRE_SOC' # PolarFire board support
    '-e' 'SOC_VIRT' '-e' 'PCI_HOST_GENERIC' # QEMU support
    '-m' 'MMC_DW_PLTFM' '-m' 'MMC_DW'
)

if [[ -z "$1" ]]; then
  ./scripts/config "${configs[@]}"
else
  ./scripts/config --file "$1" "${configs[@]}"
fi
