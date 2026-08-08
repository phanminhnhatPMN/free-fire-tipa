#import "MemoryUtils.h"

pid_t GetGameProcesspid(char* GameProcessName) {
    size_t length = 0;
    static const int name[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    int err = sysctl((int *)name, (sizeof(name) / sizeof(*name)) - 1, NULL, &length, NULL, 0);
    
    if (err == 0 && length > 0) {
        struct kinfo_proc *procBuffer = (struct kinfo_proc *)malloc(length);
        if (procBuffer == NULL) return -1;
        
        err = sysctl((int *)name, (sizeof(name) / sizeof(*name)) - 1, procBuffer, &length, NULL, 0);
        if (err == 0) {
            int count = (int)length / sizeof(struct kinfo_proc);
            for (int i = 0; i < count; ++i) {
                const char *procname = procBuffer[i].kp_proc.p_comm;
                pid_t Processpid = procBuffer[i].kp_proc.p_pid;
                
                if (strstr(procname, "freefire") || strcasestr(procname, "freefire") || strcasestr(procname, "ff")) {
                    free(procBuffer);
                    return Processpid;
                }
            }
        }
        free(procBuffer);
    }
    
    return -1;
}

vm_map_offset_t GetGameModule_Base(char* GameProcessName) {
    vm_map_offset_t vmoffset = 0;
    vm_map_size_t vmsize = 0;
    uint32_t nesting_depth = 0;
    struct vm_region_submap_info_64 vbr;
    mach_msg_type_number_t vbrcount = 16;
    
    pid_t pid = GetGameProcesspid(GameProcessName);
    if (pid == -1) return 0;
    
    if (get_task == MACH_PORT_NULL || !MACH_PORT_VALID(get_task)) {
        task_for_pid(mach_task_self(), pid, &get_task);
    }
    
    if (get_task != MACH_PORT_NULL && MACH_PORT_VALID(get_task)) {
        kern_return_t kr = mach_vm_region_recurse(get_task, &vmoffset, &vmsize, &nesting_depth, (vm_region_recurse_info_t)&vbr, &vbrcount);
        if (kr == KERN_SUCCESS) {
            return vmoffset;
        }
    }
    
    return 0;
}

bool _read(uint64_t addr, void *buffer, int len) {
    if (!isVaildPtr(addr)) return false;
    
    pid_t pid = GetGameProcesspid((char*)"freefire");
    if (pid != -1 && (get_task == MACH_PORT_NULL || !MACH_PORT_VALID(get_task))) {
        task_for_pid(mach_task_self(), pid, &get_task);
    }
    
    if (get_task == MACH_PORT_NULL || !MACH_PORT_VALID(get_task)) return false;
    
    vm_size_t size = 0;
    kern_return_t error = vm_read_overwrite(get_task, (vm_address_t)addr, len, (vm_address_t)buffer, &size);
    return (error == KERN_SUCCESS && size == len);
}

bool _write(uint64_t addr, const void *buffer, int len) {
    if (!isVaildPtr(addr)) return false;
    
    pid_t pid = GetGameProcesspid((char*)"freefire");
    if (pid != -1 && (get_task == MACH_PORT_NULL || !MACH_PORT_VALID(get_task))) {
        task_for_pid(mach_task_self(), pid, &get_task);
    }
    
    if (get_task == MACH_PORT_NULL || !MACH_PORT_VALID(get_task)) return false;

    kern_return_t kr = vm_write(get_task, (vm_address_t)addr, (vm_offset_t)buffer, (mach_msg_type_number_t)len);
    return (kr == KERN_SUCCESS);
}
