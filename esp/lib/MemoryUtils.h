#ifndef MemoryUtils_h
#define MemoryUtils_h

#include <mach/mach.h>
#include <sys/sysctl.h>
#include <string>
#include <stdint.h>

#pragma mark - Get PID

static mach_port_t get_task = MACH_PORT_NULL;
static pid_t Processpid = -1;

extern "C" kern_return_t mach_vm_region_recurse(vm_map_t                 map,
                                                mach_vm_address_t        *address,
                                                mach_vm_size_t           *size,
                                                uint32_t                 *depth,
                                                vm_region_recurse_info_t info,
                                                mach_msg_type_number_t   *infoCnt);

inline bool isVaildPtr(uint64_t addr) {
    return addr >= 0x100000000ULL && addr <= 0x7FFFFFFFFFFULL;
}

pid_t GetGameProcesspid(char* GameProcessName);
vm_map_offset_t GetGameModule_Base(char* GameProcessName);

bool _read(uint64_t addr, void *buffer, int len);
bool _write(uint64_t addr, const void *buffer, int len);

template<typename T>
T ReadAddr(uint64_t address) {
    T data{};
    _read(address, reinterpret_cast<void *>(&data), sizeof(T));
    return data;
}

template<typename T>
bool WriteAddr(uint64_t address, const T &data) {
    return _write(address, reinterpret_cast<const void *>(&data), sizeof(T));
}

#endif
