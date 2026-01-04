# XYRIS_OS
## Disclaimer

This source code is designed to work **only with Free Fire** for the specific season/version available at the time of publication.  
It is **not compatible with other games**, and functionality is **not guaranteed for future updates or seasons**.


## How to use?
**1. Get the PID and task port of your game:**
```
Current:
- (void)SetUpBase {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Moudule_Base = (uint64_t)GetGameModule_Base((char*)"freefireth");
    });
}

```

**2. Read world addresses and pointers like this.:**
```c
long Gworld = ReadAddr<long>(Moudule_Base + 0x23456789);
long Pointer = ReadAddr<long>(Gworld + 0x123);

```

### Archive Note
This code create at 2026 by LDVQuang2306.<br>

## Acknowledgements

This project would not have been possible without the support and contributions of the open-source community. I would like to sincerely thank the following GitHub contributors for their time, knowledge, and assistance:

- Fl0rk: https://github.com/Fl0rk/External_ESP_Free_Fire

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


> _"Some paths dissolve as others take form. iOS continues to evolve, time moves forward, and I am shaped along with it."_ — **LDVQuang2306**
