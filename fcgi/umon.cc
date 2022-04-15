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
#include "utils.h"

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

// Uncomment the next line to get copious debug traces on stderr:
//#define DEBUG
#ifdef DEBUG
   #define logT      std::cerr
#else
   #define logT      false && std::cerr
#endif // DEBUG

const std::vector <std::pair <std::string, std::string>> timespans =
{  // url-component & RRDtool param -> drop-down visible selector
   {"1h",       "1 hour"},
   {"3h",       "3 hours"},
   {"6h",       "6 hours"},
   {"12h",      "12 hours"},
   {"24h",      "24 hours"},
   {"2d",       "2 days"},
   {"7d",       "7 days"},
   {"14d",      "14 days"},
   {"1mon",     "1 month"},
   {"3mon",     "3 months"},
   {"6mon",     "6 months"},
   {"1y",       "1 year"},
   {"2y",       "2 years"},
};

const std::string timespan_default = "2d";

const std::unordered_map <std::string, std::string> ctypes =
{
   {"css",      "text/css"},
   {"ico",      "image/x-icon"},
   {"jpeg",     "image/jpeg"},
   {"jpg",      "image/jpeg"},
   {"js",       "application/javascript"},
   {"png",      "image/png"},
   {"txt",      "text/plain"},
};

const std::string ctype_default = "application/octet-stream";

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
   logT << "begin_request: role=" << role
        << " flags=" << (int)req->body.flags
        << std::endl;

   if (role != FCGI_RESPONDER)
   {
      std::cerr << "Unsupported FCGI role " << role << std::endl;
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

void error_page (const std::string& status)
{
   std::ostringstream output;
   output << "<h2>" << status << "</h2>";

   std::ostringstream header;
   header << "Status: " << status << "\r\n"
          << "Content-type: text/html\r\n"
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

void error_400 ()
{
   error_page ("400 Bad Request");
}

void error_404 ()
{
   error_page ("404 Not Found");
}

void
write_view_header (std::ostringstream& output,
                   const std::vector <std::string>& views,
                   const std::string& view, const std::string& timespan)
{
   char hostname [255];
   if (gethostname (hostname, sizeof (hostname)) < 0)
      return;

   output << R"raw(<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<link rel="stylesheet" href="/style.css">
<title>)raw";
   output << hostname << ":" << view << "/" << timespan << " | uMon";
   output << R"raw(</title>
<script>
function onMenu ()
{
   var form = document.forms ["menu"];
   var view = form ["view"].value;
   var timespan = form ["timespan"].value;
   window.location.href = "/view/" + view + "/" + timespan;
}
</script>
</head>

<body>

<div id="nav">
<form id="menu" action="javascript:;" onsubmit="onMenu()">
   <label for="view">View:</label>
   <select id="view" name="view" onchange="onMenu()">
)raw";

   for (const auto& v: views)
   {
      output << "      <option value=\"" << v << "\"";
      if (v == view)
         output << " selected";
      output << ">" << v << "</option>\n";
   }

   output << R"raw(   </select>
   <label for="timespan">last</label>
   <select id="timespan" name="timespan" onchange="onMenu()">
)raw";

   for (const auto& tp: timespans)
   {
      output << "      <option value=\"" << tp.first << "\"";
      if (tp.first == timespan)
         output << " selected";
      output << ">" << tp.second << "</option>\n";
   }

   output << R"raw(   </select>
   <input type="submit" value="Refresh">
</form>
</div>
)raw";
}

void
write_view_footer (std::ostringstream& output)
{
   output << R"raw(
</body>
</html>
)raw";
}

std::vector <std::string>
get_views ()
{
   namespace fs = std::filesystem;

   std::vector <std::string> vs;

   std::ifstream conffile ("./view.conf", std::ios::binary);

   while (conffile.good ())
   {
      std::string line;
      std::getline (conffile, line);
      trim_right (trim_left (line));
      if (line.size () && line [0] != '#')
         vs.push_back (line);
   }

   return vs;
}

void
process_view (const std::string& view)
{
   logT << "process_view: '" << view << "'" << std::endl;

   std::vector <std::string> ps;
   split (view, ps, '/');

   auto views = get_views ();
   {
      auto it = std::find (views.begin (), views.end (), ps [0]);
      if (it == views.end ())
         error_400 ();
   }

   std::string timespan = timespan_default;
   if (ps.size () > 1)
   {
      auto it = std::find_if (timespans.begin (), timespans.end (),
                              [&] (const auto& p)
                              {
                                 return p.first == ps [1];
                              });
      if (it == timespans.end ())
         ps [1] = timespan;
   }
   else
      ps.push_back (timespan);

   std::ostringstream output;
   std::string argv0 = ps [0] + ".sh";
   std::string path = "./views/" + argv0;
   std::vector <char*> argv;
   argv.push_back ((char*)argv0.c_str ());
   for (int k = 1; k < ps.size (); ++k)
      argv.push_back ((char*)ps [k].c_str ());
   argv.push_back (nullptr);
   write_view_header (output, views, ps [0], ps [1]);
   if (child (path.c_str (), argv.data (), nullptr, output))
      error_400 ();
   write_view_footer (output);

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
   logT << "process_graph: '" << graph << "'" << std::endl;

   std::vector <std::string> ps;
   split (graph, ps, '/');

   std::ostringstream output;
   std::string argv0 = ps [0] + ".sh";
   std::string path = "./graphs/" + argv0;
   std::vector <char*> argv;
   argv.push_back ((char*)argv0.c_str ());
   for (int k = 1; k < ps.size (); ++k)
      argv.push_back ((char*)ps [k].c_str ());
   argv.push_back (nullptr);
   if (child (path.c_str (), argv.data (), nullptr, output))
      error_400 ();
   logT << "output read: " << output.str ().size () << std::endl;

   std::ostringstream header;
   header << "Content-type: image/png\r\n"
          << "Content-length: " << output.str ().size () << "\r\n";

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
serve_static (const std::string& uri)
{
   logT << "serve_static: uri='" << uri << "'" << std::endl;

   std::string path = "./static_assets" + uri;
   logT << "path: " << path << std::endl;

   std::ifstream file (path, std::ios::binary | std::ios::ate);
   if (!file.good ())
      error_404 ();

   std::streamsize size = file.tellg ();
   file.seekg (0, std::ios::beg);

   std::vector <char> buffer (size);
   if (!file.read (buffer.data (), size))
      error_400 ();

   logT << "file data read: " << size << std::endl;

   std::vector <std::string> ps;
   split (uri, ps, '.');

   std::string ctype = ctype_default;
   if (ps.size () > 1)
   {
      auto it = ctypes.find (ps [ps.size () - 1]);
      if (it != ctypes.end ())
         ctype = it->second;
   }

   std::ostringstream header;
   header << "Content-type: " << ctype << "\r\n"
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

   const auto& uri_ = params ["DOCUMENT_URI"];
   const auto& uri = (uri_ == "/") ? "/view/main" : uri_;
   const auto& query = params ["QUERY_STRING"];
   logT << "process_request: uri='" << uri << "' q='" << query << "'"
        << std::endl;

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
   else
      serve_static (uri);
}

void
parse_params (char* buf, uint16_t contentLength)
{
   if (!contentLength)
   {
      for (const auto& p: params)
         logT << "'" << p.first << "' = '" << p.second << "'" << std::endl;

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
      logT << "stdin: '" << input.str () << "'" << std::endl;

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

      logT << "\nFCGI_Header v=" << (int)hdr->version
           << " type=" << (int)hdr->type
           << " requestId=" << requestId
           << " contentLength=" << contentLength
           << " paddingLength=" << (int)hdr->paddingLength
           << std::endl;

      if (hdr->version != FCGI_VERSION_1)
      {
         std::cerr << "Unsupported FCGI version " << (int)hdr->version
                   << std::endl;
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
         std::cerr << "Unhandled FCGI request type: " << (int)hdr->type
                   << std::endl;
         break;
      }
   }
   return 0;
};
