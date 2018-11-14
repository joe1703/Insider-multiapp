#ifndef DRAMC_WRITE_MULTIPLEXER_CPP_
#define DRAMC_WRITE_MULTIPLEXER_CPP_

#include <insider_kernel.h>

void dramC_write_multiplexer(
    ST_Queue<Dram_Write_Req_Data> &dramC_write_req_data,
    ST_Queue<Dram_Write_Req_Apply> &dramC_write_req_apply,
    ST_Queue<Dram_Write_Req_Data> &host_dramC_write_req_data,
    ST_Queue<Dram_Write_Req_Apply> &host_dramC_write_req_apply,
    ST_Queue<Dram_Write_Req_Data> &device_dramC_write_req_data,
    ST_Queue<Dram_Write_Req_Apply> &device_dramC_write_req_apply) {
  // state = 0: no outstanding dram write transaction
  // state = 1: outstanding write req from host-side interface
  // state = 2: outstanding write req from device-side interface
  unsigned int state = 0;

  while (1) {
#pragma HLS pipeline
    if (state == 0) {
      Dram_Write_Req_Apply req_apply;
      if (host_dramC_write_req_apply.read_nb(req_apply)) {
        state = 1;
        dramC_write_req_apply.write(req_apply);
      } else if (device_dramC_write_req_apply.read_nb(req_apply)) {
        state = 2;
        dramC_write_req_apply.write(req_apply);
      }
    } else if (state == 1) {
      Dram_Write_Req_Data req_data;
      if (host_dramC_write_req_data.read_nb(req_data)) {
        dramC_write_req_data.write(req_data);
        if (req_data.last) {
          state = 0;
        }
      }
    } else if (state == 2) {
      Dram_Write_Req_Data req_data;
      if (device_dramC_write_req_data.read_nb(req_data)) {
        dramC_write_req_data.write(req_data);
        if (req_data.last) {
          state = 0;
        }
      }
    }
  }
}

#endif
