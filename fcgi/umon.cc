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
#include "fcgi.h"

#include <algorithm>
#include <chrono>
#include <ctime>
#include <fstream>
#include <iostream>
#include <iterator>
#include <sstream>
#include <string>
#include <tuple>
#include <unordered_map>
#include <utility>
#include <vector>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

constexpr const size_t bufsize = FCGI_HEADER_LEN + 256 + 65536;
char buf [bufsize];

uint16_t requestId;
std::unordered_map <std::string, std::string> params;
std::ostringstream input;
bool has_params = false;
bool has_input = false;

std::chrono::time_point <std::chrono::system_clock> request_start_time;

template <class Container>
void split (const std::string& str, Container& container, char delim = ' ')
{
   std::stringstream ss (str);
   std::string token;
   while (std::getline (ss, token, delim))
      container.push_back (token);
}

int
read_buf (char* buf, size_t toRead)
{
   if (!toRead)
      return 0;

   int pos = 0;
   int rem = toRead;

   while (rem)
   {
      ssize_t rd = read (STDIN_FILENO, buf + pos, rem);
      if (rd < 0)
      {
         perror ("read: ");
         exit (1);
      }

      if (rd == 0)
         return 1; // signal EOF

      pos += toRead;
      rem -= toRead;
   }

   return 0;
}

void
begin_request (FCGI_BeginRequest* req)
{
   request_start_time = std::chrono::system_clock::now ();

   uint16_t role = req->body.roleHi << 8 | req->body.roleLo;
   std::cerr << "begin_request: role=" << role
             << " flags=" << (int)req->body.flags
             << std::endl;

   if (role != FCGI_RESPONDER)
   {
      fprintf (stderr, "Unsupported FCGI role %d\n", role);
      exit (1);
   }

   params.clear ();
   input.clear ();
   has_params = false;
   has_input = false;
}

void
emit_stdout (const char* data, size_t size)
{
   FCGI_Header hdr;
   hdr.type = FCGI_STDOUT;
   hdr.requestIdHi = requestId >> 8;
   hdr.requestIdLo = requestId & 0xff;
   hdr.contentLengthHi = size >> 8;
   hdr.contentLengthLo = size & 0xff;
   hdr.paddingLength = 0;

   std::cout.write ((const char*)&hdr, FCGI_HEADER_LEN);
   std::cout.write (data, size);
   std::cout.flush ();
}

void
emit_stdout (const std::string& str)
{
   emit_stdout (str.data (), str.size ());
}

void
emit_end_request ()
{
   FCGI_EndRequest req;
   req.header.type = FCGI_END_REQUEST;
   req.header.requestIdHi = requestId >> 8;
   req.header.requestIdLo = requestId & 0xff;
   req.header.contentLengthHi = 0;
   req.header.contentLengthLo = 8;

   std::cout.write ((const char*)&req, sizeof (req));
   std::cout.flush ();
}

void error_page ()
{
   // TODO this should be a real http error, not a successfully served html page
   std::ostringstream output;
   output << "<h2>404 Not found</h2>";

   std::ostringstream header;
   header << "Content-type: text/html\r\n"
          << "Content-length: " << output.str ().length () << "\r\n";

   using namespace std::literals;
   const auto now = std::chrono::system_clock::now ();
   header << "X-Generated-In: " << (now - request_start_time) / 1us << " us";
   header << "\r\n\r\n";

   emit_stdout (header.str ());
   emit_stdout (output.str ());
   emit_stdout ("");
   emit_end_request ();

   exit (0);
}

void
process_view (const std::string& view)
{
   std::cerr << "processing view: " << view << std::endl;
   // TODO sanitize that view contains only approved chars
   // before we pass it to exec
   std::ostringstream output;
   std::string argv0 = view + ".sh";
   std::string path = "./views/" + argv0;
   char* argv [] = {(char*)argv0.c_str (), nullptr};
   if (child (path.c_str (), argv, nullptr, output))
      error_page ();

   // TODO post-process output (add header with timespan selector, etc.)

   std::ostringstream header;
   header << "Content-type: text/html\r\n"
          << "Content-length: " << output.str ().length () << "\r\n";

   using namespace std::literals;
   const auto now = std::chrono::system_clock::now ();
   header << "X-Generated-In: " << (now - request_start_time) / 1us << " us";
   header << "\r\n\r\n";

   emit_stdout (header.str ());
   emit_stdout (output.str ());
   emit_stdout ("");
   emit_end_request ();

   exit (0);
}

void
process_graph (const std::string& graph)
{
   std::cerr << "processing graph: " << graph << std::endl;

   std::vector <std::string> ps;
   split (graph, ps, '/');

   std::ostringstream output;
   std::string argv0 = ps [0] + ".sh";
   std::string prog_path = "./graphs/" + argv0;
   std::vector <char*> argv;
   argv.push_back ((char*)argv0.c_str ());
   for (int k = 1; k < ps.size (); ++k)
      argv.push_back ((char*)ps [k].c_str ());
   argv.push_back (nullptr);
   if (child (prog_path.c_str (), argv.data (), nullptr, output))
      error_page ();
   std::cerr << output.str () << std::endl;

   std::ostringstream image_path;
   image_path << "./images/" << ps [0];
   for (int k = 1; k < ps.size (); ++k)
      image_path << "-" << ps [k];
   image_path << ".png";
   std::cerr << "image path: " << image_path.str () << std::endl;

   std::ifstream file (image_path.str (), std::ios::binary | std::ios::ate);
   if (!file.good ())
      error_page ();

   std::streamsize size = file.tellg();
   file.seekg (0, std::ios::beg);

   std::vector <char> buffer (size);
   if (!file.read (buffer.data(), size))
      error_page ();

   std::cerr << "file data read: " << size << std::endl;
   std::ostringstream header;
   header << "Content-type: image/png\r\n"
          << "Content-length: " << size << "\r\n";

   using namespace std::literals;
   const auto now = std::chrono::system_clock::now ();
   header << "X-Generated-In: " << (now - request_start_time) / 1us << " us";
   header << "\r\n\r\n";

   emit_stdout (header.str ());
   emit_stdout (buffer.data (), size);
   emit_stdout ("");
   emit_end_request ();

   exit (0);
}

void
process_request ()
{
   if (!has_params || !has_input)
      return;

   const auto& uri = params ["DOCUMENT_URI"];
   const auto& query = params ["QUERY_STRING"];
   std::cerr << "process request:" << " uri='" << uri << "' q='" << query
             << "'" << std::endl;

   if (uri.find ("/view/") == 0)
   {
      const auto& view = uri.substr (std::string ("/view/").length ());
      process_view (view);
   }
   else if (uri.find ("/graph/") == 0)
   {
      const auto& graph = uri.substr (std::string ("/graph/").length ());
      process_graph (graph);
   }

   error_page ();
}

void
parse_params (char* buf, uint16_t contentLength)
{
   if (!contentLength)
   {
      for (const auto& p: params)
         std::cerr << "'" << p.first << "' = '" << p.second << "'" << std::endl;

      has_params = true;
      process_request ();
      return;
   }

   int pos = 0;
   while (pos < contentLength)
   {
      uint32_t name_len;
      if (buf [pos] >> 7)
      {
         name_len = (buf [pos++] & 0x7f) << 24;
         name_len |= buf [pos++] << 16;
         name_len |= buf [pos++] << 8;
         name_len |= buf [pos++];
      }
      else
         name_len = buf [pos++];

      uint32_t value_len;
      if (buf [pos] >> 7)
      {
         value_len = (buf [pos++] & 0x7f) << 24;
         value_len |= buf [pos++] << 16;
         value_len |= buf [pos++] << 8;
         value_len |= buf [pos++];
      }
      else
         value_len = buf [pos++];

      params.emplace (std::piecewise_construct,
                      std::forward_as_tuple (buf + pos, name_len),
                      std::forward_as_tuple (buf + pos + name_len, value_len));

      pos += name_len;
      pos += value_len;
   }
}

void
buffer_stdin (char* buf, uint16_t contentLength)
{
   if (!contentLength)
   {
      std::cerr << "stdin: '" << input.str () << "'" << std::endl;

      has_input = true;
      process_request ();
      return;
   }

   input << std::string (buf, contentLength);
}

int
main (int argc, char** argv)
{
   while (1)
   {
      if (read_buf (buf, FCGI_HEADER_LEN))
         return 0;

      int pos = FCGI_HEADER_LEN;

      FCGI_Header* hdr = (FCGI_Header*)buf;
      requestId = hdr->requestIdHi << 8 | hdr->requestIdLo;
      uint16_t contentLength = hdr->contentLengthHi << 8 | hdr->contentLengthLo;

      std::cerr << "\nFCGI_Header v=" << (int)hdr->version
                << " type=" << (int)hdr->type
                << " requestId=" << requestId
                << " contentLength=" << contentLength
                << " paddingLength=" << (int)hdr->paddingLength
                << std::endl;

      if (hdr->version != FCGI_VERSION_1)
      {
         fprintf (stderr, "Unsupported FCGI version %d\n", hdr->version);
         exit (1);
      }

      size_t toRead = contentLength + hdr->paddingLength;
      if (read_buf (buf + pos, toRead))
         return 0;

      switch (hdr->type)
      {
      case FCGI_BEGIN_REQUEST:
         begin_request ((FCGI_BeginRequest*)buf);
         break;
      case FCGI_PARAMS:
         parse_params (buf + FCGI_HEADER_LEN, contentLength);
         break;
      case FCGI_STDIN:
         buffer_stdin (buf + FCGI_HEADER_LEN, contentLength);
         break;
      default:
         fprintf (stderr, "Unhandled FCGI request type: %u\n", hdr->type);
         break;
      }
   }
   return 0;
};
