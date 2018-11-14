if [ -z "$LLVM_SRC_PATH" ]; then
    echo "Need to set LLVM_SRC_PATH"
    exit 1
fi

if [ -z "$LLVM_BUILD_PATH" ]; then
    echo "Need to set LLVM_BUILD_PATH"
    exit 1
fi

if [ -z "$AWS_FPGA_PATH" ]; then
    echo "Need to set AWS_FPGA_PATH"
    exit 1
fi

orig_path=`pwd`

sudo mkdir -p /opt/Xilinx/license
sudo cp lic/XilinxAWS.lic /opt/Xilinx/license/XilinxAWS.lic

sudo cp patch/boost/queue.hpp /usr/include/boost/lockfree
sudo cp patch/aws/cosim/sh_bfm.sv $AWS_FPGA_PATH/hdk/common/verif/models/sh_bfm
sudo cp patch/aws/cosim/sh_dpi_tasks.svh $AWS_FPGA_PATH/hdk/common/verif/include
sudo cp patch/aws/runtime/fpga_pci.h $AWS_FPGA_PATH/sdk/userspace/include/fpga_pci.h
sudo cp patch/aws/runtime/fpga_pci.c $AWS_FPGA_PATH/sdk/userspace/fpga_libs/fpga_pci/fpga_pci.c

sudo mkdir /usr/include/staccel
sudo cp STAccel/inc/staccel* /usr/include/staccel
sudo cp -r STAccel/inc/hls_csim /usr/include
sudo mkdir /usr/staccel/
sudo cp -r STAccel/template /usr/staccel
g++ STAccel/src/iopinChecker.cpp -std=c++11 -O3 \
    -o staccel_pinckr
sudo mv staccel_pinckr /usr/bin
sudo cp STAccel/shell/* /usr/bin

sudo mkdir /usr/include/insider
sudo cp Insider/inc/* /usr/include/insider
cd Insider/lib; ./compile.sh; 
sudo mv libinsider_runtime.so /usr/lib64;
cd ../..;

echo -e "\nadd_clang_subdirectory(s2s-kernel)" \
    >> $LLVM_SRC_PATH/tools/clang/tools/CMakeLists.txt
echo "add_clang_subdirectory(s2s-interconnect)" \
    >> $LLVM_SRC_PATH/tools/clang/tools/CMakeLists.txt
echo "add_clang_subdirectory(csim-interconnect)" \
    >> $LLVM_SRC_PATH/tools/clang/tools/CMakeLists.txt
cp -r STAccel/llvm/* $LLVM_SRC_PATH/tools/clang/tools
cd $LLVM_BUILD_PATH
cmake3 $LLVM_SRC_PATH
make -j16
sudo make install

cd $orig_path
