/* ioctl related defines */
#define VSNIFF_IOC_MAGIC	'i'
#define VSNIFF_GETCLKCNT    _IO(VSNIFF_IOC_MAGIC, 0x43)

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>

int main(int argc, const char *argv[])
{
  int fd;
  if ((fd = open("/dev/video0", O_RDWR)) < 0) {
    printf("Open error on /dev/video0\n");
    exit(0);
  }

  unsigned long int  res = 0;
  ioctl(fd, VSNIFF_GETCLKCNT, &res);

  printf("clk cnt is: %u\n", res);

  close(fd);
  return 0;
}
