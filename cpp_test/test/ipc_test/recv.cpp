#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>

static int pipefd;

void handle_signal(int signum) {
  printf("Process received signal %d\n", signum);
  char buffer[256];

  lseek(pipefd, 0, SEEK_SET);
  ssize_t count = read(pipefd, buffer, 255);
  if (count <= 0) {
    perror("read");
    exit(EXIT_FAILURE);
  }
  buffer[count] = '\0';
  printf("Received: %s\n", buffer);
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    printf("Argument number error!\n");
    return 1;
  }
  pipefd = std::atoi(argv[1]);
  printf("open pipe file: %d\n", pipefd);

  signal(SIGUSR1, handle_signal);
  while (1) {
    pause();
  }
  return 0;
}
