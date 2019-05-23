/* ioctl related defines */
#define VSNIFF_IOC_MAGIC	'i'
#define VSNIFF_SETMODE_RGB	_IO(VSNIFF_IOC_MAGIC, 0x40)

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

  ioctl(fd, VSNIFF_SETMODE_RGB);

  close(fd);
  return 0;
}
