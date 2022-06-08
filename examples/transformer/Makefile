BINARY_NAME = fast_transformer
CUDA_PATH   = /usr/local/cuda
CC			= $(CUDA_PATH)/bin/nvcc
CFLAGS		= -O3 -std=c++11 -w
LDFLAGS		= -L$(CUDA_PATH)/lib64 -lcudart -lcublas -lcudadevrt -lcudart_static -lrt -lpthread
INCFLAGS	= -I$(CUDA_PATH)/include -I$(CUDA_PATH)/samples/common/inc -I /data00/home/yujia.zhai/cutlass/include -I /data00/home/yujia.zhai/cutlass/tools/util/include/
CUTLASS_GEN = -gencode=arch=compute_80,code=sm_80 -Xptxas -v

SRC			= $(wildcard *.cu)
build : $(BINARY_NAME)

$(BINARY_NAME): $(SRC)
	$(CC) $(CFLAGS) $(LDFLAGS) $(INCFLAGS) $(SRC) $(CUTLASS_GEN) -o $(BINARY_NAME)

clean:
	rm $(BINARY_NAME)
