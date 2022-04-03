/* This file is part of uMon.
 * Copyright (c) 2022 Tom Szilagyi <tom.szilagyi@altmail.se>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include "child.h"

#include <string>

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

int
child (const char* path, char *const argv [], char *const envp [],
       std::ostringstream& output)
{
   /* This is the classic setup with two pipes between the main and
    * child process: first pipe (fd1 array) carries input from main to
    * child, second pipe (fd2 array) carries output from child to
    * main. Each pipe is represented by an array of file descriptors,
    * of which [0] is for reading the pipe, and [1] is for writing to
    * the pipe.
    */
   int fd1 [2];
   int fd2 [2];

   if (pipe (fd1) == -1)
   {
      perror ("pipe");
      return 1;
   }

   if (pipe (fd2) == -1)
   {
      perror ("pipe");
      return 1;
   }

   pid_t p = fork ();
   if (p < 0)
   {
      perror ("fork");
      return 1;
   }
   else if (p > 0)  // parent process
   {
      // Close pipe ends that do not make sense to use at this point
      close (fd1 [0]);
      close (fd2 [1]);

      // Here we could write to the child's stdin, if we wanted to.
      close (fd1 [1]);

      // The only thing we actually do is read the stdout of the child process
      while (1)
      {
         char buf [1024];

         int rd = read (fd2 [0], buf, sizeof (buf));
         if (rd < 0)
         {
            perror ("read");
            break;
         }
         else if (rd == 0)
            break;

         output << (std::string (buf, rd));
      }
      close (fd2 [0]);

      int status;
      waitpid (p, &status, 0);

      if (WIFEXITED (status))
         return WEXITSTATUS (status);
      else if (WIFSIGNALED (status))
         return -WTERMSIG (status);
      else
         return 0;
   }
   else  // child process
   {
      // Close pipe ends that do not make sense to use at this point
      close (fd1 [1]);
      close (fd2 [0]);

      // Attach pipe to stdin/out
      dup2 (fd1 [0], STDIN_FILENO);
      dup2 (fd2 [1], STDOUT_FILENO);
      close (fd1 [0]);
      close (fd2 [1]);

      // Execute program
      if (execve (path, argv, envp) == -1)
      {
         perror ("execve");
         exit (1);
      }
   }
   return 0;
}
