#ifndef CONFIG_NANDFCTRL2_ENABLE
#define CONFIG_NANDFCTRL2_ENABLE 0
#endif

#ifndef CONFIG_NFC2_NROFCE
#define CONFIG_NFC2_NROFCE 0
#endif

#ifndef CONFIG_NFC2_NROFCH
#define CONFIG_NFC2_NROFCH 0
#endif

#ifndef CONFIG_NFC2_NROFRB
#define CONFIG_NFC2_NROFRB 0
#endif

#ifndef CONFIG_NFC2_NROFSEFI
#define CONFIG_NFC2_NROFSEFI 0
#endif

#ifndef CONFIG_NFC2_RND
#define CONFIG_NFC2_RND 0
#endif

#ifndef CONFIG_NFC2_MEM0_DATA
#define CONFIG_NFC2_MEM0_DATA 0
#endif

#ifndef CONFIG_NFC2_MEM0_SPARE
#define CONFIG_NFC2_MEM0_SPARE 0
#endif

#ifndef CONFIG_NFC2_MEM0_ECC_SEL
#define CONFIG_NFC2_MEM0_ECC_SEL 0
#endif

#ifndef CONFIG_NFC2_MEM1_DATA
#define CONFIG_NFC2_MEM1_DATA 0
#endif

#ifndef CONFIG_NFC2_MEM1_SPARE
#define CONFIG_NFC2_MEM1_SPARE 0
#endif

#ifndef CONFIG_NFC2_MEM1_ECC_SEL
#define CONFIG_NFC2_MEM1_ECC_SEL 0
#endif

#ifndef CONFIG_NFC2_MEM2_DATA
#define CONFIG_NFC2_MEM2_DATA 0
#endif

#ifndef CONFIG_NFC2_MEM2_SPARE
#define CONFIG_NFC2_MEM2_SPARE 0
#endif

#ifndef CONFIG_NFC2_MEM2_ECC_SEL
#define CONFIG_NFC2_MEM2_ECC_SEL 0
#endif

#ifndef CONFIG_NFC2_ECC0_GFSIZE
#define CONFIG_NFC2_ECC0_GFSIZE 0
#endif

#ifndef CONFIG_NFC2_ECC0_CHUNK
#define CONFIG_NFC2_ECC0_CHUNK 0
#endif

#ifndef CONFIG_NFC2_ECC0_CAP
#define CONFIG_NFC2_ECC0_CAP 0
#endif

#ifndef CONFIG_NFC2_ECC1_GFSIZE
#define CONFIG_NFC2_ECC1_GFSIZE 0
#endif

#ifndef CONFIG_NFC2_ECC1_CHUNK
#define CONFIG_NFC2_ECC1_CHUNK 0
#endif

#ifndef CONFIG_NFC2_ECC1_CAP
#define CONFIG_NFC2_ECC1_CAP 0
#endif

#ifndef CONFIG_NFC2_RST_CYCLES
#define CONFIG_NFC2_RST_CYCLES 10
#endif

#ifndef CONFIG_NFC2_TAG_SIZE
#define CONFIG_NFC2_TAG_SIZE 0
#endif

#if defined CONFIG_NFC2_FT_DMR
#define CONFIG_NFC2_FT 1
#elif defined CONFIG_NFC2_FT_TMR
#define CONFIG_NFC2_FT 2
#elif defined CONFIG_NFC2_FT_BCH
#define CONFIG_NFC2_FT 4
#elif defined CONFIG_NFC2_FT_TECHSPEC
#define CONFIG_NFC2_FT 5
#else
#define CONFIG_NFC2_FT 0
#endif
