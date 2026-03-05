#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mman.h>
#include <sys/socket.h>

#include <cstdint>
#include <format>
#include <string>
#include <cstring>

static void sendfd(int sv[2], int fd) {
  close(sv[0]);
  struct msghdr msg = {0};
  char buf[3] = {'A', 'B', 'C'};
  struct iovec io = { .iov_base = buf, .iov_len = 3 };

  msg.msg_iov = &io;
  msg.msg_iovlen = 1;

  char control_buf[CMSG_SPACE(sizeof(fd))];
  msg.msg_control = control_buf;
  msg.msg_controllen = sizeof(control_buf);

  struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
  cmsg->cmsg_level = SOL_SOCKET;
  cmsg->cmsg_type = SCM_RIGHTS;
  cmsg->cmsg_len = CMSG_LEN(sizeof(fd));

  *((int *)CMSG_DATA(cmsg)) = fd;

  if (sendmsg(sv[1], &msg, 0) == -1) {
    perror("sendmsg");
    exit(EXIT_FAILURE);
  }
  close(sv[1]);
}

static int recvfd(int sv[2]) {
  close(sv[1]);
  struct msghdr msg = {0};
  char buf[3] = {'A', 'B', 'C'};
  struct iovec io = { .iov_base = buf, .iov_len = sizeof(buf) };

  msg.msg_iov = &io;
  msg.msg_iovlen = 1;

  char control_buf[CMSG_SPACE(sizeof(int))];
  msg.msg_control = control_buf;
  msg.msg_controllen = sizeof(control_buf);

  if (recvmsg(sv[0], &msg, 0) == -1) {
    perror("recvmsg");
    exit(EXIT_FAILURE);
  }

  struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
  if (cmsg == NULL || cmsg->cmsg_len != CMSG_LEN(sizeof(int))) {
    fprintf(stderr, "Invalid cmsg length\n");
    exit(EXIT_FAILURE);
  }

  int received_fd = *((int *)CMSG_DATA(cmsg));
  printf("Received fd: %d\n", received_fd);
  close(sv[0]);
  return received_fd;
}

static std::string getMemFileName(int memfd) {
  pid_t pid = getpid();
  // read /proc/pid/fd/memfd
  return std::format("/proc/{}/fd/{}", pid, memfd);
}

static pid_t exec(int sv[2], int fd) {
  pid_t pid = fork();
  printf("fork subprocess: %d\n", pid);
  if (pid == -1) {
    perror("fork error...");
    return -1;
  } else if (pid == 0) {
    printf("run device_proc\n");
    auto rfd = recvfd(sv);
    std::string pipef = std::to_string(rfd);
    char *const argv[] = {"recv_exe", (char *)pipef.c_str(), NULL};
    execv("device_proc", argv);
  } else {
    sendfd(sv, fd);
  }
  return pid;
}

static void wait_sub_proc(pid_t pid) {
  int status;
  if (waitpid(pid, &status, 0) == -1) {
    perror("waitpid");
  }
  if (WIFEXITED(status)) {
    printf("Child process exited with status %d\n", WEXITSTATUS(status));
  }
}

int main() {
  int memfd = memfd_create("my_memfd", FD_CLOEXEC);
  if (memfd < 0) {
    perror("Failed to open memory file...");
    return -1;
  }
  printf("create memory fd: %d\n", memfd);

  int sv[2]; // 创建一个socket pair
  if (socketpair(AF_UNIX, SOCK_DGRAM, 0, sv) == -1) {
      perror("socketpair");
      exit(EXIT_FAILURE);
  }

  pid_t sub_pid = exec(sv, memfd);

  const char *data = "Hello world!";
  auto len = strlen(data);
  if (write(memfd, data, len) != len) {
    perror("fwrite");
  }


  sleep(1);
  kill(sub_pid, SIGUSR1);
  sleep(3);
//  while (true) {
//    sleep(1);
//  }
  wait_sub_proc(sub_pid);
  close(memfd);
  return 0;
}
